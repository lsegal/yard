require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Proxy do
  before { Registry.clear }
  
  it "should return the object if it's in the Registry" do
    pathobj = ModuleObject.new(nil, :YARD)
    Registry.should_receive(:at).at_least(:once).with("YARD").and_return(pathobj)
    proxyobj = P(:root, :YARD)
    proxyobj.type.should == :module
  end
  
  it "should handle complex string namespaces" do
    ModuleObject.new(:root, :A)
    pathobj = ModuleObject.new(P(nil, :A), :B)
    P(:root, "A::B").should be_instance_of(ModuleObject)
  end
  
  it "should return the object if it's an included Module" do
    yardobj = ModuleObject.new(:root, :YARD)
    pathobj = ClassObject.new(:root, :TestClass)
    pathobj.mixins << yardobj
    P(P(nil, :TestClass), :YARD).should be_instance_of(ModuleObject)
  end

  it "should make itself obvious that it's a proxy" do
    pathobj = P(:root, :YARD)
    pathobj.class.should == Proxy
  end    

  it "should pretend it's the object's type if it can resolve" do
    pathobj = ModuleObject.new(:root, :YARD)
    proxyobj = P(:root, :YARD)
    proxyobj.should be_instance_of(ModuleObject)
  end
  
  it "should handle instance method names" do
    obj = P(nil, '#test')
    obj.name.should == :test
    obj.path.should == "#test"
    obj.namespace.should == Registry.root
  end
  
  it "should handle instance method names under a namespace" do
    pathobj = ModuleObject.new(:root, :YARD)
    obj = P(pathobj, "A::B#test")
    obj.name.should == :test
    obj.path.should == "A::B#test"
  end
end