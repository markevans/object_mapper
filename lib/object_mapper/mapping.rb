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
      output ||= initial_class(out_rec).new
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

    private

    def initial_class(rec)
      # rec should be @left_rec or @right_rec
      case rec.method_types.first
      when :array_reader then Array
      when :hash_reader  then Hash
      end
    end

  end
end
