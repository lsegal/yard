require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::ClassObject do
  before do 
    Registry.clear 
    @mixin = ModuleObject.new(:root, :SomeMixin)
    @mixin2 = ModuleObject.new(:root, :SomeMixin2)
    @superyard = ClassObject.new(:root, :SuperYard)
    @superyard.superclass = P("String")
    @superyard.mixins << @mixin2
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

describe YARD::CodeObjects::ClassObject, "#meths / #inherited_meths" do
  before do 
    Registry.clear 
    
    # setup the object space:
    # 
    #   SuperYard:class
    #   SuperYard#foo:method
    #   SuperYard#foo2:method
    #   SuperYard#bar:method
    #   SuperYard::bar:method
    #   YARD#mymethod:method
    #   YARD#bar:method
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
    MethodObject.new(@superyard, :bar)
    @yard = ClassObject.new(:root, :YARD)
    @yard.superclass = @superyard
    MethodObject.new(@yard, :bar)
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
  
  it "should not show overridden methods" do 
    meths = @yard.meths
    meths.should include(P("YARD#bar"))
    meths.should_not include(P("SuperYard#bar"))
    
    meths = @yard.inherited_meths
    meths.should_not include(P("YARD#bar"))
    meths.should_not include(P("YARD#mymethod"))
    meths.should include(P("SuperYard#foo"))
    meths.should include(P("SuperYard#foo2"))
    meths.should include(P("SuperYard::bar"))
  end
end

describe YARD::CodeObjects::ClassObject, "#constants / #inherited_constants" do
  before do 
    Registry.clear 
    
    Parser::SourceParser.parse_string <<-eof
      class YARD
        CONST1 = 1
        CONST2 = "hello"
      end
      
      class SubYard < YARD
        CONST2 = "hi"
        CONST3 = "foo"
      end
    eof
  end
  
  it "should list inherited constants by default" do
    consts = P(:SubYard).constants
    consts.should include(P("YARD::CONST1"))
    consts.should include(P("SubYard::CONST3"))
    
    consts = P(:SubYard).inherited_constants
    consts.should include(P("YARD::CONST1"))
    consts.should_not include(P("YARD::CONST2"))
    consts.should_not include(P("SubYard::CONST2"))
    consts.should_not include(P("SubYard::CONST3"))
  end
  
  it "should not list inherited constants if turned off" do
    consts = P(:SubYard).constants(false)
    consts.should_not include(P("YARD::CONST1"))
    consts.should include(P("SubYard::CONST3"))
  end
  
  it "should count CONST2 once as part of SubYard" do
    consts = P(:SubYard).constants
    consts.should include(P("SubYard::CONST2"))
    consts.should_not include(P("YARD::CONST2"))
  end
end
  
