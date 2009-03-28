module ObjectMapper
    
  # Exceptions
  class MappingSpecificationError < StandardError; end

  module Mapper

    def mapper_classes(left,right)
      @left_class, @right_class = left, right
    end

    def will_map(mapping_list)
      mapping_list.each{|from,to| mappings << Mapping.new(from, to) }
    end

    def obj
      MethodCallRecorder.new
    end

    def map(input)
      map_in_direction(:ltr, input)
    end

    def demap(input)
      map_in_direction(:rtl, input)
    end

    private
    
    def map_in_direction(direction, input) # direction is either :rtl or :ltr
      output = output_class(direction) ? output_class(direction).new : nil
      mappings.each do |mapping|
        mapping.reverse! if direction == :rtl
        output = mapping.map(input, output)
      end
      output
    end

    def extract_from(mapping_spec, &blk)
      extracted_pairs = []
      mapping_spec.each do |k,v|
        if yield(k,v)
          extracted_pairs << [k,v]
          mapping_spec.delete(k)
        end
      end
      extracted_pairs
    end

    def input_class(direction)
      direction == :ltr ? @left_class : @right_class
    end
    
    def output_class(direction)
      direction == :ltr ? @right_class : @left_class
    end

    def mappings
      @mappings ||= []
    end

  end
end