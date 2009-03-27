require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

def stub_method_call(*args)
  method_call = mock('method_call')
  MethodCall.stub!(:new).with(*args).and_return method_call
  method_call
end

describe MethodCallRecorder do

  before(:each) do
    @rec = MethodCallRecorder.new
  end

  it "should allow any combination of chained methods on it" do
    lambda do
      MethodCallRecorder.new.egg[23]['fish'].another = 5
      MethodCallRecorder.new[:twenty].what.the / 8 * 4 + 1
    end.should_not raise_error
  end

  it "should save methods called on it in it's 'method chain'" do
    mc1 = stub_method_call(:this, :should)
    mc2 = stub_method_call(:[], 'be')
    mc3 = stub_method_call(:saved)
    @rec.this(:should)['be'].saved
    @rec.method_chain.should == [mc1, mc2, mc3]
  end

  it "should be able to play back its method chain on another object" do
    inner = mock('inner', :duck => 'hello')
    struct = mock('struct', :fish => inner)
    obj = { :a => [struct, 2] }
    @rec[:a][0].fish.duck
    @rec.play(obj).should == 'hello'
  end

  it "should just return the object on play if its method chain is empty" do
    obj = Object.new
    @rec.play(obj).should == obj
  end

  it "should record append to the method chain if you record twice" do
    mc1 = stub_method_call(:once)
    mc2 = stub_method_call(:twice)
    @rec.once
    @rec.method_chain.should == [mc1]
    @rec.twice
    @rec.method_chain.should == [mc1, mc2]
  end

  it "should allow resetting the method chain" do
    mc1 = stub_method_call(:once)
    mc2 = stub_method_call(:twice)
    @rec.once
    @rec.method_chain.should == [mc1]
    @rec._reset!
    @rec.twice
    @rec.method_chain.should == [mc1, mc2]
  end

  it "should yield the current sub object, and the next two methods to be called as it plays back" do
    mc1 = MethodCall.new(:[], :hello)
    mc2 = MethodCall.new(:[], 2)
    mc3 = MethodCall.new(:eggy_bread)
    str = 'yes'
    def str.eggy_bread; 'egg'; end
    @rec[:hello][2].eggy_bread
    yielded_values = []
    @rec.play({:hello => ['no','and',str]}) do |obj, method_call, next_method_call|
      yielded_values << [obj, method_call, next_method_call]
    end
    yielded_values.should == [
      [ {:hello => ['no','and',str]}, mc1, mc2 ],
      [ ['no','and',str],             mc2, mc3 ],
      [ str,                          mc3, nil ]
    ]
  end

  it "should return the methods (without args) called on it" do
    @rec.hello[:boy].how('are').you?
    @rec.methods.should == [:hello, :[], :how, :you?]
  end

  it "should return the first method type called on it" do
    @rec.hello[3][:who?].egg = 4
    @rec._first_method_type.should == :attr_reader
  end

  it "should return itself" do
    @rec.hello[4].this(:is).now('innit').should == @rec
  end
  
  it "should return a clone of itself with the last method as a setter" do
    mc1 = MethodCall.new(:[], :hello)
    mc2 = MethodCall.new(:there)
    mc3 = MethodCall.new(:there=, 4)
    @rec[:hello].there
    other_rec = @rec.to_setter(4)
    @rec.method_chain.should      == [mc1, mc2]
    other_rec.method_chain.should == [mc1, mc3]
  end

end