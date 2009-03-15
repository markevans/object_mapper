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
  
  describe "duplication" do
    before(:each) do
      @mc1 = MethodCall.new(:[], 3)
      @mc2 = @mc1.deep_dup
    end
    it "should be able to duplicate itself" do
      @mc2.should be_instance_of(MethodCall)
    end
    it "should deep clone its method" do
      @mc2.send(:method=, :hi)
      @mc2.method.should == :hi # Just to check
      @mc1.method.should == :[] 
    end
    it "should deep clone its args" do
      @mc2.args << :gog
      @mc2.args.should == [3, :gog] # Just to check
      @mc1.args.should == [3]
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
    
    it "should not change itself" do
      method_call = MethodCall.new(:[], 3)
      setter = method_call.to_setter('yo')
      method_call.to_a.should == [:[], 3]
    end

  end
  
  describe "getting the type" do
    it "should detect hash readers" do
      MethodCall.new(:[], 'there').type.should == :hash_reader
    end
    it "should detect hash writers" do
      MethodCall.new(:[]=, 'there', 4).type.should == :hash_writer
    end
    it "should detect array readers" do
      MethodCall.new(:[], 7).type.should == :array_reader
    end
    it "should detect array writer" do
      MethodCall.new(:[]=, 3, 5).type.should == :array_writer
    end
    it "should detect getters" do
      MethodCall.new(:undre).type.should == :attr_reader
    end
    it "should detect setters" do
      MethodCall.new(:bob=, 'there').type.should == :attr_writer
    end
    
  end
  
  describe "comparing with other method calls" do
    it "should return as equal if both have same method and args" do
      MethodCall.new(:yes, 'sadf', :ue, 4).should == MethodCall.new(:yes, 'sadf', :ue, 4)
    end
    it "should return as not equal if same method but different args" do
      MethodCall.new(:yes, 'sadf', 4).should_not == MethodCall.new(:yes, 'sadf', :ue, 4)
    end
    it "should return as not equal if same args but different method" do
      MethodCall.new(:yes, 'sadf', :ue, 4).should_not == MethodCall.new(:no, 'sadf', :ue, 4)
    end
    it "should return as not equal if different method and args" do
      MethodCall.new(:yes, 'sadf', :ue, 4).should_not == MethodCall.new(:no, 3, 5, 'sdf')
    end
  end
  
  describe "ensuring method can be called on an obj" do

    describe "when the cumulative method chain is empty" do
      it "should create a hash if necessary" do
        MethodCall.new(:[],:hello).ensure_obj_can_call('poo').should == {}
      end

      it "should create an array if necessary" do
        MethodCall.new(:[],4).ensure_obj_can_call('poo').should == []
      end

      it "should not overwrite a hash if it already exists" do
        MethodCall.new(:[],:hello).ensure_obj_can_call({:g => 4}).should == {:g => 4}
      end

      it "should not overwrite an array if it already exists" do
        MethodCall.new(:[],4).ensure_obj_can_call([7,8,9]).should == [7,8,9]
      end
    end

  end

end