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
    
    def to_a
      [method, *args]
    end
    
    def setter?
      !!(method.to_s =~ /=$/)
    end
    
    def getter?
      !setter?
    end
    
    def to_setter(value)
      new_method_call = self.dup
      if setter?
        new_method_call.args[-1] = value
      else
        new_method_call.args << value
        new_method_call.method = "#{new_method_call.method}=".to_sym
      end
      new_method_call
    end
    
    protected
    
    attr_writer :method
    
  end
end