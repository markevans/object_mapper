module ObjectMapper
  class MethodCallRecorder

    def initialize(parent=nil)
      @parent = parent
    end

    def play(object, &blk)
      i = 0
      method_chain.inject(object) do |obj, method_call|
        i += 1
        yield(obj, method_call, method_chain[i]) if block_given?
        method_call.call_on(obj)
      end
    end

    def methods
      method_chain.map{|method_call| method_call.method }
    end

    def method_types
      method_chain.map{|method_call| method_call.type }
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

    def method_chain
      @method_chain ||= []
    end
    
    def to_setter(value)
      new_rec = self.dup
      new_rec.method_chain = self.method_chain.dup
      new_rec.method_chain[-1] = self.method_chain[-1].to_setter(value)
      new_rec
    end

    protected

    attr_writer :method_chain

    def add_to_method_chain(meth, *args)
      method_chain << MethodCall.new(meth, *args)
      parent.add_to_method_chain(meth, *args) if parent
    end

    attr_reader :parent, :child

    private

    def method_missing(meth, *args)
      @method_chain = []
      add_to_method_chain(meth, *args)
      @child = self.class.new(self)
    end

  end
end