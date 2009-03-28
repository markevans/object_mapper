module ObjectMapper
    
  # Exceptions
  class MappingSpecificationError < StandardError; end

  module Mapper

    def mapper_classes(left,right)
      @left_class, @right_class = left, right
    end

    def will_map(mapping_spec)
      left_value_mapper, right_value_mapper = extract_value_mappers_from(mapping_spec)
      mapping_spec.each do |from,to|
        mappings << Mapping.new(from, to, :left_value_mapper => left_value_mapper,
                                          :right_value_mapper => right_value_mapper)
      end
    end

    def will_map_using(value_mapper, mapping_spec)
      mapping_spec.each do |from,to|
        mappings << Mapping.new(from, to, :left_value_mapper => value_mapper.method(:demap),
                                          :right_value_mapper => value_mapper.method(:map))
      end
    end

    def obj
      MethodCallRecorder.new
    end
    
    def val(&blk)
      lambda(&blk)
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

    def extract_value_mappers_from(mapping_spec)
      value_mappers = []
      mapping_spec.each do |k,v|
        if k.is_a? Proc
          value_mappers << [k,v]
          mapping_spec.delete(k)
        end
      end
      raise MappingSpecificationError, "you can only specify the value mapper once" if value_mappers.size > 1
      value_mappers.first
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