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
    it "should initialize the output on reverse_map when classes are stated explicitly" do
      Class1.should_receive(:new).and_return @obj1
      ExplicitMapperClass.reverse_map(@obj2).should == @obj1
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
    it "should be able to reverse_map a nested hash/array correctly from a single mapping" do
      SingleMapperClass.reverse_map([:a, {:this => 'is', :quite => 'Good'}, :b]).should == {:hello => [nil,nil,'is']}
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
      MultiMapperClass.reverse_map(@to).should == @from
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
  
  describe "value mapping" do
    describe "using the value mapper on each mapping" do
      before :each do
        class ValueMapper
          extend ObjectMapper::Mapper
          will_map val{|v| v.upcase} => val{|v| v.downcase },
                   obj[0]            => obj[:a],
                   obj[1]            => obj[:b]
        end
        @from = ['ONE','TWO']
        @to = {:a => 'one', :b => 'two'}
      end
      it "should map using the value mapper" do
        ValueMapper.map(@from).should == @to
      end
      it "should reverse map using the value mapper" do
        ValueMapper.reverse_map(@to).should == @from
      end
      it "should raise an error if too many value mappers specified" do
        lambda{
          class TooManyVMs
            extend ObjectMapper::Mapper
            will_map val{} => val{}, val{} => val{}
          end
        }.should raise_error(ObjectMapper::MappingSpecificationError)
      end
    end
  end
  
  describe "delegated value mapping" do
    before(:each) do
      class DelegatedMapper
        def self.map(arg)
          'delegated map!'
        end
        def self.reverse_map(arg)
          'delegated reverse_map!'
        end
      end
      class DelegatorMapper
        extend ObjectMapper::Mapper
        will_map_using DelegatedMapper,
                       obj[0] => obj['0'],
                       obj[1] => obj['1']
      end
    end
    it "should delegate value mapping for each mapping" do
      DelegatorMapper.map([:a,:b]).should == {'0' => 'delegated map!', '1' => 'delegated map!'}
    end
    it "should delegate reverse value mapping for each mapping" do
      DelegatorMapper.reverse_map({'0' => :a, '1' => :b}).should == ['delegated reverse_map!', 'delegated reverse_map!']
    end
  end

end