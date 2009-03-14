module ObjectMapper
  class MethodCallRecorder

    def initialize(parent=nil)
      @parent = parent
    end

    def playback(object, opts={}, &blk)
      if opts[:assign]
        self.class.playback_and_assign(object, self.method_chain, opts[:assign])
      else
        self.class.playback(object, self.method_chain, &blk)
      end
    end

    def methods
      method_chain.map{|meth_spec| meth_spec.first }
    end

    def method_types
      method_chain.map{|method_spec| self.class.method_type(method_spec) }
    end

    def root_ancestor
      ancestor = parent
      while ancestor.parent
        ancestor = ancestor.parent
      end
      ancestor
    end

    def to_s
      method_chain.inspect
    end

    protected

    def method_chain
      @method_chain ||= []
    end

    def add_to_method_chain(meth, *args)
      method_chain << [meth, *args]
      parent.add_to_method_chain(meth, *args) if parent
    end

    attr_reader :parent, :child

    private

    def self.method_type(method_spec)
      meth, *args = method_spec
      case meth.to_s
      when '[]'  then (args.first.is_a?(Fixnum) ? :array_reader : :hash_reader)
      when '[]=' then (args.first.is_a?(Fixnum) ? :array_writer : :hash_writer)
      when /\=$/ then :attr_writer
      else :attr_reader
      end
    end

    def self.playback(object, method_chain, &blk)
      i = 0
      method_chain.inject(object) do |obj, method_spec|
        i += 1
        yield(obj, method_spec, method_chain[i]) if block_given?
        obj.send(*method_spec)
      end
    end

    def self.playback_and_assign(object, method_chain, value)
      if  method_chain.empty?
        object = value
      else
        meth_chain = method_chain.dup
        # Turn the last method into a setter
        meth_chain[-1] = setter_method(meth_chain[-1], value)
        playback(object, meth_chain) do |obj, method_spec, next_method_spec|
          # Look ahead to the method which will be called, and pre-set it so that
          # it will return something which can carry on the chain
          sub_obj = ensure_obj_can_call_method(obj.send(*method_spec), next_method_spec) if next_method_spec
          obj.send( *setter_method(method_spec, sub_obj) )
          obj.send(*method_spec)
        end
      end
    end

    def self.ensure_obj_can_call_method(obj, method_spec)
      meth, *args = method_spec
      klass = case method_type(method_spec)
      when :array_reader, :array_writer then Array
      when :hash_reader,  :hash_writer then Hash
      end
      obj = klass.new unless obj.is_a?(klass)
      obj
    end

    def self.setter_method(method_spec, value)
      meth, *args = method_spec
      if meth.to_s =~ /=$/
        args[-1] = value
      else
        args << value
        meth = "#{meth}=".to_sym
      end
      [meth, *args]
    end

    def method_missing(meth, *args)
      @method_chain = []
      add_to_method_chain(meth, *args)
      @child = self.class.new(self)
    end

  end
end