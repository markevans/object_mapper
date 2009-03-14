module ObjectMapper
  class MethodCall
  
    def initialize(meth, *args, &blk)
      @method, @args = meth, args
      @block = blk
    end
  
    attr_reader :method, :args, :block
  
  end
end