module ObjectMapper
  
  # Exceptions
  class MappingError < StandardError; end
  class MappingInputError  < MappingError; end
  class MappingOutputError < MappingError; end
  
  class Mapping

    def initialize(left_rec, right_rec, opts={})
      @left_rec  = left_rec
      @right_rec = right_rec
      @direction = :ltr
      @left_value_mapper = opts[:left_value_mapper]
      @right_value_mapper = opts[:right_value_mapper]
    end

    def map(input, output)
      begin
        value = in_rec._play(input)
        value = value_mapper.call(value)
      rescue NoMethodError, ArgumentError => e
        raise MappingInputError, "Couldn't apply mapping to input: #{e.message}"
      end
      assign_to_object(output, value)
    end

    # Reverse the direction of the mapping
    def reverse!
      @direction = (@direction == :ltr ? :rtl : :ltr)
      self
    end

    private
    
    def in_rec
      @direction == :ltr ? @left_rec : @right_rec
    end
    
    def out_rec
      @direction == :ltr ? @right_rec : @left_rec
    end

    def value_mapper
      @direction == :ltr ? right_value_mapper : left_value_mapper
    end

    def left_value_mapper
      @left_value_mapper || lambda{|v| v }
    end
    
    def right_value_mapper
      @right_value_mapper || lambda{|v| v }
    end
    
    def assign_to_object(object, value)
      if out_rec._method_chain.empty?
        object = value
      else
        assign_rec = out_rec._to_setter(value)
        object = ensure_obj_can_call_method(object, assign_rec._method_chain.first)
        assign_rec._play(object) do |obj, method_call, next_method_call|
          # Look ahead to the method which will be called, and pre-set it so that
          # it will return something which can carry on the chain
          sub_obj = method_call.call_on(obj)
          sub_obj = ensure_obj_can_call_method(sub_obj, next_method_call) if next_method_call
          method_call.to_setter(sub_obj).call_on(obj)
          method_call.call_on(obj)
        end
      end
      object
    end
    
    def ensure_obj_can_call_method(obj, method_call)
      if obj.respond_to?(method_call.method)
        obj
      else
        klass = method_call.guess_receiver_type
        klass ? klass.new : raise(MappingOutputError, "Couldn't call #{method_call.method} on #{obj.class}")
      end
    end

  end
end
