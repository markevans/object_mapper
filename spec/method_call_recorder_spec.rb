require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

describe MethodCallRecorder do

  before(:each) do
    @rec          = MethodCallRecorder.new
  end

  it "should allow any combination of chained methods on it" do
    lambda do
      MethodCallRecorder.new.egg[23]['fish'].another = 5
      MethodCallRecorder.new[:twenty].what.the / 8 * 4 + 1
    end.should_not raise_error
  end

  it "should save methods called on it in it's 'method chain'" do
    @rec.this(:should)['be'].saved
    @rec.send(:method_chain).should == [ [:this, :should],
      [:[],   'be'   ],
      [:saved        ]
    ]
  end

  it "should be able to play back its method chain on another object" do
    inner = mock('inner', :duck => 'hello')
    struct = mock('struct', :fish => inner)
    obj = { :a => [struct, 2] }
    @rec[:a][0].fish.duck
    @rec.playback(obj).should == 'hello'
  end

  it "should just return the object on playback if its method chain is empty" do
    obj = Object.new
    @rec.playback(obj).should == obj
  end

  it "should reset the method chain if you try to record twice" do
    @rec.once[3]
    @rec.send(:method_chain).should == [[:once], [:[],3]]
    @rec.twice[:laugh]
    @rec.send(:method_chain).should == [[:twice], [:[],:laugh]]
  end

  it "should be able to play back and assign a value" do
    @rec[:hello][:there]
    obj = {:hello => {:there => 'yo'}}
    @rec.playback(obj, :assign => 'after')
    obj .should == {:hello => {:there => 'after'}}
  end

  it "should yield the current sub object, and the next two methods to be called as it plays back" do
    @rec[:hello][2].upcase
    yielded_values = []
    @rec.playback({:hello => ['no','and','yes']}) do |obj, method_spec, next_method_spec|
      yielded_values << [obj, method_spec, next_method_spec]
    end
    yielded_values.should == [
      [ {:hello => ['no','and','yes']}, [:[],:hello],    [:[],2]   ],
      [ ['no','and','yes'],             [:[],2],         [:upcase] ],
      [ 'yes',                          [:upcase],       nil       ]
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

  describe "making methods into setters" do

    it "should turn [] into a setter" do
      MethodCallRecorder.send(:setter_method, [:[], 3], 'hello').should == [:[]=, 3, 'hello']
    end

    it "should leave []= as it is but assign new value" do
      MethodCallRecorder.send(:setter_method, [:[]=, 3, 5], 'hello').should == [:[]=, 3, 'hello']
    end

    it "should turn an arbitrary method call into a setter" do
      MethodCallRecorder.send(:setter_method, [:hello, 'there'], 65).should == [:hello=, 'there', 65]
    end

    it "should turn [] into a setter" do
      MethodCallRecorder.send(:setter_method, [:[],3], 'hello').should == [:[]=,3,'hello']
    end

  end

  describe "constructing with hashes" do

    before(:each) do
      @rec[:a]
    end

    it "should add to a hash" do
      obj = {:b => 'already'}
      @rec.playback(obj, :assign => 'pigweed')
      obj.should == {:a => 'pigweed', :b => 'already'}
    end

    it "should overwrite a hash key" do
      obj = {:a => 'already'}
      @rec.playback(obj, :assign => 'pigweed')
      obj.should == {:a => 'pigweed'}
    end

  end

  describe "dealing with arrays" do

    before(:each) do
      @rec[2]
    end

    it "should construct an array if the key doesn't already exist" do
      obj = []
      @rec.playback(obj, :assign => 'pigweed')
      obj.should == [nil, nil, 'pigweed']
    end

    it "should add to an array" do
      obj = [nil, 'already']
      @rec.playback(obj, :assign => 'pigweed')
      obj.should == [nil, 'already', 'pigweed']
    end

    it "should overwrite an array entry" do
      obj = ['one', :two, 'three', :four]
      @rec.playback(obj, :assign => 'pigweed')
      obj.should == ['one', :two, 'pigweed', :four]
    end

  end

  describe "ensuring method can be called on obj" do

    describe "when the cumulative method chain is empty" do
      it "should create a hash if necessary" do
        MethodCallRecorder.send(:ensure_obj_can_call_method, nil, [:[],:hello]).should == {}
      end

      it "should create an array if necessary" do
        MethodCallRecorder.send(:ensure_obj_can_call_method, 'dog', [:[],3]).should == []
      end

      it "should not overwrite a hash if it already exists" do
        MethodCallRecorder.send(:ensure_obj_can_call_method, {:g => 4}, [:[],:hello]).should == {:g => 4}
      end

      it "should not overwrite an array if it already exists" do
        MethodCallRecorder.send(:ensure_obj_can_call_method, [5,4,3], [:[],5]).should == [5,4,3]
      end
    end

  end

  describe "constructing objects when assigning" do

    before(:each) do
      @rec[2][:hello][1]['ssup']
    end

    it "should construct a nested object if it starts as empty" do
      obj = []
      @rec.playback(obj, :assign => 'yo')
      obj.should == [nil, nil, {:hello => [nil, {'ssup' => 'yo'}]} ]
    end

    it "should construct a nested object and override a hash key if necessary" do
      obj = [3,4,{:how_are => 'you', :hello => 'there'}]
      @rec.playback(obj, :assign => (4..5))
      obj.should == [3, 4, {:how_are => 'you', :hello => [nil, {'ssup' => (4..5)}] }]
    end

    it "should construct a nested object and override an array key if necessary" do
      obj = [:a, :b, :c, :d]
      @rec.playback(obj, :assign => 'done')
      obj.should == [:a, :b, {:hello => [nil, {'ssup' => 'done'}]}, :d]
    end

  end

end