require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

describe MethodCall do
  
  before(:each) do
    @method_call = MethodCall.new(:hello, 4, 'yo')
  end
  
  it "should return the method name" do
    
    @method_call.method.should == :hello
  end
  it "should return the args" do
    @method_call.args.should == [4, 'yo']
  end
  it "should return the block as nil if not given" do
    @method_call.block.should be_nil
  end
  it "should return the block if given" do
    method_call = MethodCall.new(:hi){ |doobie| puts doobie }
    method_call.block.should be_kind_of(Proc)
  end
end