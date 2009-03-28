require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

describe Mapping do

  before(:each) do
    @rec1, @rec2 = MethodCallRecorder.new, MethodCallRecorder.new
    @mapping = Mapping.new(@rec1, @rec2)
  end

  describe "mapping" do
    before(:each) do
      @rec1[:hello][2]
      @rec2[1]['yo']
    end
    it "should correctly map arrays/hashes from left to right" do
      @mapping.map({:yo => 3, :hello => [88,99,100,333]}, []).should == [nil, {'yo' => 100}]
    end
    it "should be able to reverse the direction of the mapping and return itself" do
      @mapping.reverse!.should == @mapping
      @mapping.map([3, {'yo' => 100, :a => :b}], {}).should == {:hello => [nil,nil,100]}
    end
  end

  describe "initializing objects" do
    it "should guess the initial object as an array when the mapping has square brackets and integer" do
      @rec2[1]
      @mapping.map('yo', nil).should == [nil, 'yo']
    end
    it "should guess the initial object as a hash when the mapping has square brackets and sommink else" do
      @rec2[:hi]
      @mapping.map('yo', nil).should == {:hi => 'yo'}
    end
  end

  describe "simple and complex mappings" do
    it "should be able to map from a simple object to a simple one" do
      @mapping.map('bingo', nil).should == 'bingo'
    end
    it "should be able to map from a simple object to a complex one" do
      @rec2[:hello][1]
      @mapping.map('bingo', {}).should == {:hello => [nil, 'bingo']}
    end
    it "should be able to map from a complex object to a simple one" do
      @rec1[:hello][1]
      @mapping.map({:hello => [nil, 'bingo']}, nil).should == 'bingo'
    end
  end

  describe "constructing the output" do
    describe "dealing with hashes" do
      before(:each) do
        @rec2[:a]
      end
      it "should add to a hash" do
        @mapping.map('pigweed', {:b => 'already'}).should == {:a => 'pigweed', :b => 'already'}
      end
      it "should overwrite a hash key" do
        @mapping.map('pigweed', {:a => 'already'}).should == {:a => 'pigweed'}
      end
    end

    describe "dealing with arrays" do
      before(:each) do
        @rec2[2]
      end
      it "should construct an array if the key doesn't already exist" do
        @mapping.map('pigweed', []).should == [nil, nil, 'pigweed']
      end
      it "should add to an array" do
        @mapping.map('pigweed', [nil, 'already']).should == [nil, 'already', 'pigweed']
      end
      it "should overwrite an array entry" do
        @mapping.map('pigweed', ['one', :two, 'three', :four]).should == ['one', :two, 'pigweed', :four]
      end
    end

    describe "nested objects" do
      before(:each) do
        @rec2[2][:hello][1]['ssup']
      end
      it "should construct a nested object if it starts as empty" do
        @mapping.map('yo', []).should == [nil, nil, {:hello => [nil, {'ssup' => 'yo'}]} ]
      end
      it "should construct a nested object and override a hash pair if necessary" do
        @mapping.map(:dude, [3,4,{:how_are => 'you', :hello => :there}]).
          should == [3, 4, {:how_are => 'you', :hello => [nil, {'ssup' => :dude}] }]
      end
      it "should construct a nested object and override an array key if necessary" do
        @mapping.map('done', [:a, :b, :c, :d]).should == [:a, :b, {:hello => [nil, {'ssup' => 'done'}]}, :d]
      end
    end
  end

  describe "mapping errors" do
    before(:each) do
      @x, @y = Object.new, Object.new
      @left = {:hi => @x}
      @right = [@y]
      @rec1[:hi].one
      @rec2[0].two
    end

    it "should raise an error if the mapped from object doesn't respond to a method call" do
      def @y.two; end
      lambda{ @mapping.map(@left, @right) }.should raise_error(ObjectMapper::MappingInputError)
    end
    it "should raise an error if the mapper tries a method call on the input with wrong args" do
      def @x.one(arg_1); end
      def @y.two; end
      lambda{ @mapping.map(@left, @right) }.should raise_error(ObjectMapper::MappingInputError)
    end
    it "should raise an error if the mapped to object doesn't respond to a method call" do
      def @x.one; end
      lambda{ @mapping.map(@left, @right) }.should raise_error(ObjectMapper::MappingOutputError)
    end
    it "should raise an error if the mapper tries a method call on the input with wrong args" do
      def @x.one; end
      def @y.two(arg_1); end
      lambda{ @mapping.map(@left, @right) }.should raise_error(ObjectMapper::MappingOutputError)
    end
  end

  describe "iterating over arrays" do
    before(:each) do
      pending "Need to implement!"
      @rec1[:hello][]
      @rec2[]['yo']
    end
    it "should map each element of an array if empty square brackets given" do
      @mapping.map({:hello => [:a, :b]}, []).should == [{'yo' => :a}, {'yo' => :b}]
    end
  end

end
