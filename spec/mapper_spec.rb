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
    
    it "should raise an error if classes need specifying" do
      lambda {
        class ClassesNeedSpecifying
          extend ObjectMapper::Mapper
          will_map obj.hi => obj['yo']
        end
      }.should raise_error(ObjectMapper::MappingSpecificationError)
    end
    
    it "should determine automatically if square brackets are used" do
      class ImplicitMapperClass
        extend ObjectMapper::Mapper
        will_map obj[:hello][2] => obj[1][:this]
      end
      ImplicitMapperClass.send(:left_mapper_class).should  == Hash
      ImplicitMapperClass.send(:right_mapper_class).should == Array
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

end