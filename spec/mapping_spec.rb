require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

describe Mapping do
  
  before(:each) do
    @rec1, @rec2 = MethodCallRecorder.new.hello.there, MethodCallRecorder.new[:egg].stuff(4)
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

end