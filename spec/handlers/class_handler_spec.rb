require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ClassHandler do
  before { parse_file :class_handler_001, __FILE__ }
  
  it "should parse a class block with docstring" do
    Registry.at("A").docstring.should == "Docstring"
  end
  
  it "should handle complex class names" do
    Registry.at("A::B::C").should_not == nil
  end
  
  it "should handle the subclassing syntax" do
    Registry.at("A::B::C").superclass.path.should == "String"
    Registry.at("A::X").superclass.should == Registry.at("A::B::C")
  end
  
  it "should interpret class << self as a class level block" do
    Registry.at("A::classmethod1").should_not == nil
  end
  
  it "should make visibility public when parsing a block" do
    Registry.at("A::B::C#method1").visibility.should == :public
  end
end