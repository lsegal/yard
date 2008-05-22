require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::NamespaceObject do
  before { Registry.clear }
  
  it "should respond to #child with the object name passed in" do
    obj = NamespaceObject.new(nil, :YARD)
    other = NamespaceObject.new(obj, :Other)
    obj.child(:Other).should == other
    obj.child('Other').should == other
  end
  
  it "should respond to #child with hash of reader attributes with their response value" do
    obj = NamespaceObject.new(nil, :YARD)
    NamespaceObject.new(obj, :NotOther)
    other = NamespaceObject.new(obj, :Other)
    other.somevalue = 2
    obj.child(:somevalue => 2).should == other
  end
  
  it "should return #meths even if parent is a Proxy" do
    obj = NamespaceObject.new(P(:String), :YARD)
    obj.meths.should be_empty
  end
  
  it "should not list included methods that are already defined in the namespace using #meths" do
    a = ModuleObject.new(nil, :Mod)
    ameth = MethodObject.new(a, :testing)
    ameth2 = MethodObject.new(a, :foo, :class)
    b = NamespaceObject.new(nil, :YARD)
    bmeth = MethodObject.new(b, :testing)
    bmeth2 = MethodObject.new(b, :foo)
    b.mixins << a
    
    meths = b.meths
    meths.should include(bmeth)
    meths.should include(bmeth2)
    meths.should include(ameth2)
    meths.should_not include(ameth)
    
    meths = b.mixin_meths
    meths.should include(ameth2)
    meths.should_not include(ameth)
    meths.should_not include(bmeth)
    meths.should_not include(bmeth2)
  end
end