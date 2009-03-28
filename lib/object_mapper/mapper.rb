module ObjectMapper
    
  # Exceptions
  class MappingSpecificationError < StandardError; end


  module Mapper

    def will_map(mapping_list)
      @left_mapper_class, @right_mapper_class = extract_classes_from_mappings(mapping_list)
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

    def extract_classes_from_mappings(mappings)
      class_mappings = mappings.select{|k,v| k.is_a? Class }
      if class_mappings.any?
        raise MappingSpecificationError, "You specified mapping classes more than once" if class_mappings.size > 1
        left, right = class_mappings.first
        mappings.delete(left)
        return [left, right]
      end
    end

    def mappings
      @mappings ||= []
    end

    attr_reader :left_mapper_class, :right_mapper_class

  end
end