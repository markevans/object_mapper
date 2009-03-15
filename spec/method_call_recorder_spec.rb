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
    @rec.send(:method_chain).should == [mc1, mc2, mc3]
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

  it "should reset the method chain if you try to record twice" do
    mc1 = stub_method_call(:once)
    mc2 = stub_method_call(:[], 3)
    @rec.once[3]
    @rec.send(:method_chain).should == [mc1, mc2]
    mc1 = stub_method_call(:twice)
    mc2 = stub_method_call(:[], :laugh)
    @rec.twice[:laugh]
    @rec.send(:method_chain).should == [mc1, mc2]
  end

  it "should be able to play back and assign a value" do
    @rec[:hello][:there]
    obj = {:hello => {:there => 'yo'}}
    @rec.play(obj, :assign => 'after')
    obj.should == {:hello => {:there => 'after'}}
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

  it "should return the method types called on it" do
    @rec.hello[3][:who?].egg = 4
    @rec.method_types.should == [:attr_reader, :array_reader, :hash_reader, :attr_writer]
  end

  it "should be able to return its root ancestor recorder object" do
    other_rec = @rec.hello[4].this(:is).now('innit')
    other_rec.should_not == @rec
    other_rec.root_ancestor.should == @rec
  end

  describe "constructing with hashes" do

    before(:each) do
      @rec[:a]
    end

    it "should add to a hash" do
      obj = {:b => 'already'}
      @rec.play(obj, :assign => 'pigweed')
      obj.should == {:a => 'pigweed', :b => 'already'}
    end

    it "should overwrite a hash key" do
      obj = {:a => 'already'}
      @rec.play(obj, :assign => 'pigweed')
      obj.should == {:a => 'pigweed'}
    end

  end

  describe "dealing with arrays" do

    before(:each) do
      @rec[2]
    end

    it "should construct an array if the key doesn't already exist" do
      obj = []
      @rec.play(obj, :assign => 'pigweed')
      obj.should == [nil, nil, 'pigweed']
    end

    it "should add to an array" do
      obj = [nil, 'already']
      @rec.play(obj, :assign => 'pigweed')
      obj.should == [nil, 'already', 'pigweed']
    end

    it "should overwrite an array entry" do
      obj = ['one', :two, 'three', :four]
      @rec.play(obj, :assign => 'pigweed')
      obj.should == ['one', :two, 'pigweed', :four]
    end

  end

  describe "constructing objects when assigning" do

    before(:each) do
      @rec[2][:hello][1]['ssup']
    end

    it "should construct a nested object if it starts as empty" do
      obj = []
      @rec.play(obj, :assign => 'yo')
      obj.should == [nil, nil, {:hello => [nil, {'ssup' => 'yo'}]} ]
    end

    it "should construct a nested object and override a hash key if necessary" do
      obj = [3,4,{:how_are => 'you', :hello => 'there'}]
      @rec.play(obj, :assign => (4..5))
      obj.should == [3, 4, {:how_are => 'you', :hello => [nil, {'ssup' => (4..5)}] }]
    end

    it "should construct a nested object and override an array key if necessary" do
      obj = [:a, :b, :c, :d]
      @rec.play(obj, :assign => 'done')
      obj.should == [:a, :b, {:hello => [nil, {'ssup' => 'done'}]}, :d]
    end

  end

end