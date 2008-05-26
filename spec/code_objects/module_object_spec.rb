require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::ModuleObject, "#meths" do
  before do 
    Registry.clear 
    
    # setup the object space:
    # 
    #   YARD:module
    #   YARD#foo:method
    #   YARD#foo2:method
    #   YARD#xyz:method
    #   YARD::bar:method
    #   SomeMod#mixmethod
    #   SomeMod#xyz:method
    # 
    @yard = ModuleObject.new(:root, :YARD)
    MethodObject.new(@yard, :foo)
    MethodObject.new(@yard, :xyz)
    MethodObject.new(@yard, :foo2) do |o|
      o.visibility = :protected
    end
    MethodObject.new(@yard, :bar, :class) do |o|
      o.visibility = :private
    end
    @other = ModuleObject.new(:root, :SomeMod)
    MethodObject.new(@other, :mixmethod)
    MethodObject.new(@other, :xyz)
    
    @yard.mixins << @other
  end
  
  it "should list all methods (including mixin methods) via #meths" do
    meths = @yard.meths
    meths.should include(P("YARD#foo"))
    meths.should include(P("YARD#foo2"))
    meths.should include(P("YARD::bar"))
    meths.should include(P("SomeMod#mixmethod"))
  end
  
  it "should allow :visibility to be set" do
    meths = @yard.meths(:visibility => :public)
    meths.should_not include(P("YARD::bar"))
    meths = @yard.meths(:visibility => [:public, :private])
    meths.should include(P("YARD#foo"))
    meths.should include(P("YARD::bar"))
    meths.should_not include(P("YARD#foo2"))
  end
  
  it "should allow :scope to be set" do
    meths = @yard.meths(:scope => :class)
    meths.should_not include(P("YARD#foo"))
    meths.should_not include(P("YARD#foo2"))
    meths.should_not include(P("SomeMod#mixmethod"))
  end
  
  it "should allow :included to be set" do
    meths = @yard.meths(:included => false)
    meths.should_not include(P("SomeMod#mixmethod"))
    meths.should include(P("YARD#foo"))
    meths.should include(P("YARD#foo2"))
    meths.should include(P("YARD::bar"))
  end
  
  it "should choose the method defined in the class over an included module" do
    meths = @yard.meths
    meths.should_not include(P("SomeMod#xyz"))
    meths.should include(P("YARD#xyz"))
    
    meths = @other.meths
    meths.should include(P("SomeMod#xyz"))
  end
end