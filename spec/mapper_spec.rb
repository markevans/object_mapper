require "#{File.dirname(__FILE__)}/spec_helper"

include ObjectMapper

describe Mapper do

  describe "determining the classes to map to and from" do
    
    it "should determine them when stated explicitly" do
      class ExplicitMapperClass
        extend ObjectMapper::Mapper
        will_map  String     => Array,
                  obj.egg    => obj[1]
      end
      ExplicitMapperClass.send(:left_mapper_class).should  == String
      ExplicitMapperClass.send(:right_mapper_class).should == Array
    end
    
    it "should raise an error if classes are specified too many times" do
      lambda {
        class TooManyClassesMapper
          extend ObjectMapper::Mapper
          will_map String => Array, Hash => Array
        end
      }.should raise_error(ObjectMapper::MappingSpecificationError)
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
    it "should use the second one if more than one will_map declares the mapping classes" do
      class MultiDecClasses
        extend ObjectMapper::Mapper
        will_map String => Array
        will_map Hash => Array
        will_map obj[:hi] => obj[0]
      end
      MultiDecClasses.map({:hi => 1}).should == [1]
    end
  end

end