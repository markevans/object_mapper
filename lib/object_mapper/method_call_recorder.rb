module ObjectMapper
  class MethodCallRecorder

    def initialize(parent=nil)
      @parent = parent
    end

    def play(object, opts={}, &blk)
      if opts[:assign]
        playback_and_assign(object, method_chain, opts[:assign])
      else
        playback(object, method_chain, &blk)
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

    protected

    def method_chain
      @method_chain ||= []
    end

    def add_to_method_chain(meth, *args)
      method_chain << MethodCall.new(meth, *args)
      parent.add_to_method_chain(meth, *args) if parent
    end

    attr_reader :parent, :child

    private

    def playback(object, method_chain, &blk)
      i = 0
      method_chain.inject(object) do |obj, method_call|
        i += 1
        yield(obj, method_call, method_chain[i]) if block_given?
        method_call.call_on(obj)
      end
    end

    def playback_and_assign(object, method_chain, value)
      if  method_chain.empty?
        object = value
      else
        meth_chain = method_chain.dup
        meth_chain[-1] = meth_chain[-1].to_setter(value)
        playback(object, meth_chain) do |obj, method_call, next_method_call|
          # Look ahead to the method which will be called, and pre-set it so that
          # it will return something which can carry on the chain
          sub_obj = next_method_call.ensure_obj_can_call(method_call.call_on(obj)) if next_method_call
          method_call.to_setter(sub_obj).call_on(obj)
          method_call.call_on(obj)
        end
      end
    end

    def method_missing(meth, *args)
      @method_chain = []
      add_to_method_chain(meth, *args)
      @child = self.class.new(self)
    end

  end
end