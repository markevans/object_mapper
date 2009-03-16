module ObjectMapper
  
  # Exceptions
  class MappingError < StandardError; end
  class MappingInputError  < MappingError; end
  class MappingOutputError < MappingError; end
  
  class Mapping

    def initialize(left_rec, right_rec)
      @left_rec  = left_rec
      @right_rec = right_rec
      @direction = :ltr
    end

    def map(input, output)
      in_rec, out_rec = recorder_objects
      output = out_rec.method_chain.first.ensure_obj_can_call(output)
      begin
        value = in_rec.play(input)
      rescue NoMethodError, ArgumentError => e
        raise MappingInputError, "Couldn't apply mapping to input: #{e.message}"
      end
      begin
        out_rec.play(output, :assign => value )
      rescue NoMethodError, ArgumentError => e
        raise MappingOutputError, "Couldn't apply mapping to output: #{e.message}"
      end
      output
    end

    # Reverse the direction of the mapping
    def reverse!
      @direction = (@direction == :ltr ? :rtl : :ltr)
      self
    end

    def recorder_objects
      case @direction
      when :ltr then [@left_rec, @right_rec]
      when :rtl then [@right_rec, @left_rec]
      end
    end

  end
end
