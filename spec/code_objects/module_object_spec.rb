require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::ModuleObject, "#meths" do
  before do 
    Registry.clear 
    
    # setup the object space:
    # 
    #   YARD:module
    #   YARD#foo:method
    #   YARD#foo2:method
    #   YARD::bar:method
    #   SomeMod#mixmethod
    # 
    @yard = ModuleObject.new(:root, :YARD)
    MethodObject.new(@yard, :foo)
    MethodObject.new(@yard, :foo2) do |o|
      o.visibility = :protected
    end
    MethodObject.new(@yard, :bar, :class) do |o|
      o.visibility = :private
    end
    @other = ModuleObject.new(:root, :SomeMod)
    MethodObject.new(@other, :mixmethod)
    
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
  
  it "should allow :mixins to be set" do
    meths = @yard.meths(:mixins => false)
    meths.should_not include(P("SomeMod#mixmethod"))
    meths.should include(P("YARD#foo"))
    meths.should include(P("YARD#foo2"))
    meths.should include(P("YARD::bar"))
  end
end