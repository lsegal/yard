require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::ClassObject do
  before do 
    Registry.clear 
    @mixin = ModuleObject.new(:root, :SomeMixin)
    @superyard = ClassObject.new(:root, :SuperYard)
    @superyard.superclass = P("String")
    @yard = ClassObject.new(:root, :YARD)
    @yard.superclass = @superyard
    @yard.mixins << @mixin
  end
  
  it "should show the proper inheritance tree" do
    @yard.inheritance_tree.should == [@yard, @superyard, P(:String)]
  end
  
  it "should show proper inheritance tree when mixins are included" do
    @yard.inheritance_tree(true).should == [@yard, @mixin, @superyard, P(:String)]
  end
end

describe YARD::CodeObjects::ClassObject, "#meths" do
  before do 
    Registry.clear 
    
    # setup the object space:
    # 
    #   SuperYard:class
    #   SuperYard#foo:method
    #   SuperYard#foo2:method
    #   SuperYard::bar:method
    #   YARD#mymethod:method
    # 
    @superyard = ClassObject.new(:root, :SuperYard)
    @superyard.superclass = P(:String)
    MethodObject.new(@superyard, :foo)
    MethodObject.new(@superyard, :foo2) do |o|
      o.visibility = :protected
    end
    MethodObject.new(@superyard, :bar, :class) do |o|
      o.visibility = :private
    end
    @yard = ClassObject.new(:root, :YARD)
    @yard.superclass = @superyard
    MethodObject.new(@yard, :mymethod)
  end
  
  it "should show inherited methods by default" do
    meths = @yard.meths
    meths.should include(P("YARD#mymethod"))
    meths.should include(P("SuperYard#foo"))
    meths.should include(P("SuperYard#foo2"))
    meths.should include(P("SuperYard::bar"))
  end
  
  it "should allow :inheritance to be set to false" do
    meths = @yard.meths(:inheritance => false)
    meths.should include(P("YARD#mymethod"))
    meths.should_not include(P("SuperYard#foo"))
    meths.should_not include(P("SuperYard#foo2"))
    meths.should_not include(P("SuperYard::bar"))
  end
end