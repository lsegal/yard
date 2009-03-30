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
    # Once we have a way of dealing with class-scoped mixins,
    # we should test that a class-scoped foo method that's been included
    # is in b.meths and b.included_meths
    a = ModuleObject.new(nil, :Mod)
    ameth = MethodObject.new(a, :testing)
    b = NamespaceObject.new(nil, :YARD)
    bmeth = MethodObject.new(b, :testing)
    bmeth2 = MethodObject.new(b, :foo)
    b.mixins << a
    
    meths = b.meths
    meths.should include(bmeth)
    meths.should include(bmeth2)
    meths.should_not include(ameth)
    
    meths = b.included_meths
    meths.should_not include(ameth)
    meths.should_not include(bmeth)
    meths.should_not include(bmeth2)
  end
  
  it "should not list methods overridden by another included module" do
    a = ModuleObject.new(nil, :Mod)
    ameth = MethodObject.new(a, :testing)
    b = ModuleObject.new(nil, :Mod2)
    bmeth = MethodObject.new(b, :testing)
    c = NamespaceObject.new(nil, :YARD)
    c.mixins << a
    c.mixins << b
    
    meths = c.included_meths
    meths.should_not include(ameth)
    meths.should include(bmeth)
  end
  
  it "should list class attributes using #class_attributes" do
    a = NamespaceObject.new(nil, :Mod)
    a.attributes[:instance][:a] = { :read => MethodObject.new(a, :a), :write => nil }
    a.attributes[:instance][:b] = { :read => MethodObject.new(a, :b), :write => nil }
    a.attributes[:class][:a] = { :read => MethodObject.new(a, :a, :class), :write => nil }
    a.class_attributes.keys.should include(:a)
    a.class_attributes.keys.should_not include(:b)
  end
  
  it "should list instance attributes using #instance attributes" do
    a = NamespaceObject.new(nil, :Mod)
    a.attributes[:instance][:a] = { :read => MethodObject.new(a, :a), :write => nil }
    a.attributes[:instance][:b] = { :read => MethodObject.new(a, :b), :write => nil }
    a.attributes[:class][:a] = { :read => MethodObject.new(a, :a, :class), :write => nil }
    a.instance_attributes.keys.should include(:a)
    a.instance_attributes.keys.should include(:b)
  end
end

describe YARD::CodeObjects::NamespaceObject, '#constants/#included_constants' do
  before do
    Registry.clear
    
    Parser::SourceParser.parse_string <<-eof
      module A
        CONST1 = 1
        CONST2 = 2
      end
      
      module B
        CONST2 = -2
        CONST3 = -3
      end
      
      class C
        CONST3 = 3
        CONST4 = 4
        
        include A
        include B
      end
    eof
  end
  
  it "should list all included constants by default" do
    consts = P(:C).constants
    consts.should include(P('A::CONST1'))
    consts.should include(P('C::CONST4'))
  end
  
  it "should allow :included to be set to false to ignore included constants" do
    consts = P(:C).constants(:included => false)
    consts.should_not include(P('A::CONST1'))
    consts.should include(P('C::CONST4'))
  end
  
  it "should not list an included constant if it is defined in the object" do
    consts = P(:C).constants
    consts.should include(P('C::CONST3'))
    consts.should_not include(P('B::CONST3'))
  end
  
  it "should not list an included constant if it is shadowed by another included constant" do
    consts = P(:C).included_constants
    consts.should include(P('B::CONST2'))
    consts.should_not include(P('A::CONST2'))
  end
end
