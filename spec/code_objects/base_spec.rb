require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Base do
  before { Registry.clear }
  
  it "should return a unique instance of any registered object"
  
  it "should allow namespace to be nil and not register in the Registry" do
    obj = Base.new(nil, :Me)
    obj.namespace.should == nil
    Registry.at(:Me).should == nil
  end

  it "should allow namespace to be a NamespaceObject" do
    ns = ModuleObject.new(:root, :Name)
    obj = Base.new(ns, :Me)
    obj.namespace.should == ns
  end
  
  it "should allow :root to be the shorthand namespace of `Registry.root`" do
    obj = Base.new(:root, :Me)
    obj.namespace.should == Registry.root
  end
  
  
  it "should not allow any other types as namespace" do
    lambda { Base.new("ROOT!", :Me) }.should raise_error(ArgumentError)
  end
  
  it "should register itself in the registry if namespace is supplied" do
    obj = ModuleObject.new(:root, :Me)
    Registry.at(:Me).should == obj
    
    obj2 = ModuleObject.new(obj, :Too)
    Registry.at(:"Me::Too").should == obj2
  end
end