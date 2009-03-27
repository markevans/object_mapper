module ObjectMapper
  class MethodCallRecorder

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

    def _first_method_type
      method_chain.first.type
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
    
    def _reset!
      method_chain = []
    end

    protected
    
    attr_writer :method_chain

    private

    def method_missing(meth, *args)
      method_chain << MethodCall.new(meth, *args)
      self
    end

  end
end