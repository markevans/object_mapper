module ObjectMapper
    
  # Exceptions
  class MappingSpecificationError < StandardError; end


  module Mapper

    def will_map(mapping_list)
      mapping_list = extract_classes_from_mappings(mapping_list)
      mapping_list.each{|from,to| mappings << Mapping.new(from.root_ancestor, to.root_ancestor) }
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
        raise MappingSpecificationError, "You specified mapping classes more than once" unless class_mappings.size == 1
        @left_mapper_class, @right_mapper_class = class_mappings.first
        mappings.delete(@left_mapper_class)
      else
        @left_mapper_class, @right_mapper_class = determine_classes_from_mappings(mappings)
      end
      mappings
    end

    def determine_classes_from_mappings(mappings)
      mappings.to_a.first.map do |rec_object|
        case rec_object.root_ancestor.method_types.first
        when :array_reader then Array
        when :hash_reader  then Hash
        else raise MappingSpecificationError, "Couldn't determine which classes to map. You need to state them explicitly"
        end
      end
    end

    def mappings
      @mappings ||= []
    end

    attr_reader :left_mapper_class, :right_mapper_class

  end
end