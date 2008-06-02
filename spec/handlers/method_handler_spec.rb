require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::MethodHandler do
  before { parse_file :method_handler_001, __FILE__ }
  
  it "should add methods to parent's #meths list" do
    P(:Foo).meths.should include(P("Foo#method1"))
  end
  
  it "should parse/add class methods (self.method2)" do
    P(:Foo).meths.should include(P("Foo::method2"))
  end
  
  it "should parse/add class methods from other namespaces (String::hello)" do
    P("String::hello").should_not be_nil
  end
  
  it "should allow punctuation in method names ([], ?, =~, <<, etc.)" do
    [:[], :[]=, :allowed?, :/, :=~, :==, :`, :|, :*, :&, :%, :'^'].each do |name|
      P("Foo##{name}").should_not be_instance_of(Proxy)
    end
  end
  
  it "should mark dynamic methods as such" do
    P('Foo#dynamic').dynamic?.should == true
  end
  
  it "should show that a method is explicitly defined (if it was originally defined implicitly by attribute)" do
    P('Foo#method1').is_explicit?.should == true
  end
end