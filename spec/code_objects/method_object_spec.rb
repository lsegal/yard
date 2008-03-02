require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::MethodObject do
  before do 
    Registry.clear 
    @yard = CodeObjects::NamespaceObject.new(:root, :YARD, :class, nil, nil)
  end
  
  it "should have a path of testing for an instance method in the root" do
    meth = CodeObjects::MethodObject.new(:root, :testing, :method, :public, :instance)
    meth.path.should == :"testing"
  end
  
  it "should have a path of YARD#testing for an instance method in YARD" do
    meth = CodeObjects::MethodObject.new(@yard, :testing, :method, :public, :instance)
    meth.path.should == :"YARD#testing"
  end
  
  it "should have a path of YARD::testing for a class method in YARD" do
    meth = CodeObjects::MethodObject.new(@yard, :testing, :method, :public, :class)
    meth.path.should == :"YARD::testing"
  end
end