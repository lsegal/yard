require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::AliasHandler do
  before do
    Registry.clear 
    parse_file :alias_handler_001, __FILE__
  end

  it "should throw alias into namespace object list" do
    P(:A).aliases[:a].should == P("A#b")
  end
  
  it "should create a new method object for the alias" do
    P("A#b").should be_instance_of(MethodObject)
  end
  
  it "should pull the method into the current class if it's from another one" do
    P(:B).aliases[:x].should == P("B#q")
  end
end