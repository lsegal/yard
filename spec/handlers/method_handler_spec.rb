require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}MethodHandler" do
  before(:all) do
    log.enter_level(Logger::ERROR) do
      parse_file :method_handler_001, __FILE__ 
    end
  end
  
  it "should add methods to parent's #meths list" do
    P(:Foo).meths.should include(P("Foo#method1"))
  end
  
  it "should parse/add class methods (self.method2)" do
    P(:Foo).meths.should include(P("Foo.method2"))
  end
  
  it "should parse/add class methods from other namespaces (String.hello)" do
    P("String.hello").should be_instance_of(CodeObjects::MethodObject)
  end
  
  it "should allow punctuation in method names ([], ?, =~, <<, etc.)" do
    [:[], :[]=, :allowed?, :/, :=~, :==, :`, :|, :*, :&, :%, :'^', :-@, :+@, :'~@'].each do |name|
      Registry.at("Foo##{name}").should_not be_nil
    end
  end
  
  it "should mark dynamic methods as such" do
    P('Foo#dynamic').dynamic?.should == true
  end
  
  it "should show that a method is explicitly defined (if it was originally defined implicitly by attribute)" do
    P('Foo#method1').is_explicit?.should == true
  end
  
  it "should handle parameters" do
    P('Foo#[]').parameters.should == [['key', "'default'"]]
    P('Foo#/').parameters.should == [['x', "File.new('x', 'w')"], ['y', '2']]
  end
  
  it "should handle opts = {} as parameter" do
    P('Foo#optsmeth').parameters.should == [['x', nil], ['opts', '{}']]
  end

  it "should handle &block as parameter" do
    P('Foo#blockmeth').parameters.should == [['x', nil], ['&block', nil]]
  end

  it "should handle overloads" do
    meth = P('Foo#foo')

    o1 = meth.tags(:overload).first
    o1.name.should == :foo
    o1.parameters.should == [[:a, nil], [:b, "1"]]
    o1.tag(:return).type.should == "String"

    o2 = meth.tags(:overload)[1]
    o2.name.should == :foo
    o2.parameters.should == [[:b, nil], [:c, nil]]
    o2.tag(:return).type.should == "Fixnum"

    o3 = meth.tags(:overload)[2]
    o3.name.should == :foo
    o3.parameters.should == [[:d, nil], [:e, nil]]
    o3.docstring.should be_empty
    o3.docstring.should be_blank
  end
end
