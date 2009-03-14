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
  
  describe "call_on" do
    it "should call the method on the passed in object and return the value" do
      string = 'yoh washup'
      method_call = MethodCall.new(:gsub, 'h', 'e')
      method_call.call_on(string).should == 'yoe waseup'
    end
  end
  
  describe "to array" do
    it "should return the method and args as an array" do
      MethodCall.new(:egg, 'cheese', 5).to_a.should == [:egg, 'cheese', 5]
    end
  end
  
  describe "setter?" do
    it "should return true for a setter" do
      MethodCall.new(:doobie=, '4').setter?.should be_true
      MethodCall.new(:[]=, 2, 3).setter?.should be_true
    end
    it "should return false for a getter" do
      MethodCall.new(:doobie, '4').setter?.should be_false
      MethodCall.new(:[], 2, 3).setter?.should be_false
    end
  end
  
  describe "getter?" do
    it "should be false if setter is true" do
      @method_call.should_receive(:setter?).and_return true
      @method_call.getter?.should be_false
    end
    it "should be true if setter is false" do
      @method_call.should_receive(:setter?).and_return false
      @method_call.getter?.should be_true
    end
  end
  
  describe "making methods into setters" do

    it "should turn [] into a setter" do
      MethodCall.new(:[], 3).to_setter('hello').to_a.should == [:[]=, 3, 'hello']
    end

    it "should leave []= as it is but assign new value" do
      MethodCall.new(:[]=, 3, 5).to_setter('hello').to_a.should == [:[]=, 3, 'hello']
    end

    it "should turn an arbitrary method call into a setter by adding the value at the end of the args" do
      MethodCall.new(:hello, 'there').to_setter(65).to_a.should == [:hello=, 'there', 65]
    end

    it "should not change an arbitrary method which is already a setter but assign a new value" do
      MethodCall.new(:hello=, 'there').to_setter(65).to_a.should == [:hello=, 65]
    end

  end
  
end