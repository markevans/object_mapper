require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

describe Mapper do

  describe "the classes to map to and from" do
    before :each do
      class Class1; attr_accessor :meth_1; end
      class Class2; attr_accessor :meth_2; end
      class ExplicitMapperClass
        extend ObjectMapper::Mapper
        mapper_classes Class1, Class2
        will_map obj.meth_1 => obj.meth_2
      end
      @obj1, @obj2 = Class1.new, Class2.new
    end
    it "should initialize the output on map when classes are stated explicitly" do
      Class2.should_receive(:new).and_return @obj2
      ExplicitMapperClass.map(@obj1).should == @obj2
    end
    it "should initialize the output on demap when classes are stated explicitly" do
      Class1.should_receive(:new).and_return @obj1
      ExplicitMapperClass.demap(@obj2).should == @obj1
    end
  end

  describe "one to one mapping" do
    before(:each) do
      class OneToOne
        extend ObjectMapper::Mapper
        will_map obj => obj
      end
    end
    it "should description" do
      OneToOne.map('hello').should == 'hello'
    end
  end

  describe "single mapping" do
    
    before(:each) do
      class SingleMapperClass
        extend ObjectMapper::Mapper
        will_map obj[:hello][2] => obj[1][:this]
      end
    end
    
    it "should be able to normalize a nested hash/array correctly from a single mapping" do
      SingleMapperClass.map({:yo => 3, :hello => [88,99,100,333]}).should == [nil, {:this => 100}]
    end
    it "should be able to demap a nested hash/array correctly from a single mapping" do
      SingleMapperClass.demap([:a, {:this => 'is', :quite => 'Good'}, :b]).should == {:hello => [nil,nil,'is']}
    end
  end

  describe "multi mapping" do
    
    before(:each) do
      class MultiMapperClass
        extend ObjectMapper::Mapper
        will_map obj[:hello][1] => obj[1][:this],
                 obj[:hello][0] => obj[1][:chump]
      end
      @from = {:hello => ['one','two']}
      @to = [nil, {:this => 'two', :chump => 'one'}]
    end
    it "should be able to normalize more than one mapping on the same object" do
      MultiMapperClass.map(@from).should == @to
    end
    it "should be able to denormalize more than one mapping on the same object" do
      MultiMapperClass.demap(@to).should == @from
    end
  end
  
  describe "more than one will_map declaration" do

    it "should map using all declared mappings" do
      class MultiDec
        extend ObjectMapper::Mapper
        will_map obj[0] => obj[:hi]
        will_map obj[1] => obj[:dog]
      end
      MultiDec.map(['one', 'two']).should == {:hi => 'one', :dog => 'two'}
    end
    
  end

end