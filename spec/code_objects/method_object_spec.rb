require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::MethodObject do
  before do 
    Registry.clear 
    @yard = ModuleObject.new(:root, :YARD)
  end
  
  it "should have a path of testing for an instance method in the root" do
    meth = MethodObject.new(:root, :testing, :public, :instance)
    meth.path.should == "testing"
  end
  
  it "should have a path of YARD#testing for an instance method in YARD" do
    meth = MethodObject.new(@yard, :testing, :public, :instance)
    meth.path.should == "YARD#testing"
  end
  
  it "should have a path of YARD::testing for a class method in YARD" do
    meth = MethodObject.new(@yard, :testing, :public, :class)
    meth.path.should == "YARD::testing"
  end
end