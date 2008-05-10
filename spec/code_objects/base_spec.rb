require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Base do
  before { Registry.clear }
  
  it "should return a unique instance of any registered object" do
    obj = ClassObject.new(:root, :Me)
    obj2 = ModuleObject.new(:root, :Me)
    obj.object_id.should == obj2.object_id
    
    obj3 = ModuleObject.new(obj, :Too)
    obj4 = CodeObjects::Base.new(obj3, :Hello)
    obj4.parent = obj
    
    obj5 = CodeObjects::Base.new(obj3, :hello)
    obj4.object_id.should_not == obj5.object_id
  end
  
  it "should allow namespace to be nil and not register in the Registry" do
    obj = CodeObjects::Base.new(nil, :Me)
    obj.namespace.should == nil
    Registry.at(:Me).should == nil
  end

  it "should allow namespace to be a NamespaceObject" do
    ns = ModuleObject.new(:root, :Name)
    obj = CodeObjects::Base.new(ns, :Me)
    obj.namespace.should == ns
  end
  
  it "should allow :root to be the shorthand namespace of `Registry.root`" do
    obj = CodeObjects::Base.new(:root, :Me)
    obj.namespace.should == Registry.root
  end
  
  
  it "should not allow any other types as namespace" do
    lambda { CodeObjects::Base.new("ROOT!", :Me) }.should raise_error(ArgumentError)
  end
  
  it "should register itself in the registry if namespace is supplied" do
    obj = ModuleObject.new(:root, :Me)
    Registry.at(:Me).should == obj
    
    obj2 = ModuleObject.new(obj, :Too)
    Registry.at(:"Me::Too").should == obj2
  end
  
  it "should set any attribute using #[]=" do
    obj = ModuleObject.new(:root, :YARD)
    obj[:some_attr] = "hello"
    obj[:some_attr].should == "hello"
  end
  
  it "#[]= should use the accessor method if available" do
    obj = CodeObjects::Base.new(:root, :YARD)
    obj[:source] = "hello"
    obj.source.should == "hello"
    obj.source = "unhello"
    obj[:source].should == "unhello"
  end
end