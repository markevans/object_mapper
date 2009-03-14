module ObjectMapper
  class MethodCall
  
    def initialize(meth, *args, &blk)
      @method, @args = meth, args
      @block = blk
    end
  
    attr_reader :method, :args, :block
  
    def call_on(obj)
      obj.send(method, *args)
    end
  
  end
end