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
    P("Foo#[]").should_not be_nil
    P("Foo#[]=").should_not be_nil
    P("Foo#allowed?").should_not be_nil
    P("Foo#/").should_not be_nil
    P("Foo#==").should_not be_nil
  end
end