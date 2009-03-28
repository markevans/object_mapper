module ObjectMapper
    
  # Exceptions
  class MappingSpecificationError < StandardError; end


  module Mapper

    def will_map(mapping_list)
      @left_mapper_class, @right_mapper_class = extract_classes_from_mapping_spec(mapping_list)
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
      output = nil
      mappings.each do |mapping|
        mapping.reverse! if direction == :rtl
        output = mapping.map(input, output)
      end
      output
    end

    def extract_classes_from_mapping_spec(mapping_spec)
      class_mappings = extract_from(mapping_spec){|k,v| k.is_a? Class }
      if class_mappings.any?
        raise MappingSpecificationError, "You specified mapping classes more than once" if class_mappings.size > 1
        class_mappings.first
      end
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

    def mappings
      @mappings ||= []
    end

    attr_reader :left_mapper_class, :right_mapper_class

  end
end