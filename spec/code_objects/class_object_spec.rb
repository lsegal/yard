require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::ClassObject do
  describe '#inheritance_tree' do
    before(:all) do
      Registry.clear
      @mixin = ModuleObject.new(:root, :SomeMixin)
      @mixin2 = ModuleObject.new(:root, :SomeMixin2)
      @mixin2.instance_mixins << @mixin
      @mixin3 = ModuleObject.new(:root, :SomeMixin3)
      @mixin4 = ModuleObject.new(:root, :SomeMixin4)
      @mixin2.instance_mixins << @mixin3
      @superyard = ClassObject.new(:root, :SuperYard)
      @superyard.superclass = P("String")
      @superyard.instance_mixins << @mixin2
      @superyard.class_mixins << @mixin4
      @yard = ClassObject.new(:root, :YARD)
      @yard.superclass = @superyard
      @yard.instance_mixins << @mixin
    end

    it "should show the proper inheritance tree" do
      expect(@yard.inheritance_tree).to eq [@yard, @superyard, P(:String)]
    end

    it "should show proper inheritance tree when mixins are included" do
      expect(@yard.inheritance_tree(true)).to eq [@yard, @mixin, @superyard, @mixin4, @mixin2, @mixin3, P(:String)]
    end

    it "should not modify the object's mixin list when mixins are included" do
      @class1 = ClassObject.new(:root, :A)
      @class2 = ClassObject.new(:root, :B)
      @class2.superclass = @class1

      @class2.inheritance_tree(true)
      expect(@class2.mixins).to eq []
    end

    it "should list class mixins in inheritance tree" do
      mod = ModuleObject.new(:root, :ClassMethods)
      klass = ClassObject.new(:root, :ReceivingClass)
      klass.class_mixins << mod
      expect(klass.inheritance_tree(true)).to eq [klass, mod]
    end
  end

  describe "#meths / #inherited_meths" do
    before(:all) do
      Registry.clear

      YARD.parse_string <<-eof
        class SuperYard < String
          def foo; end
          def foo2; end
          def bar; end
          def middle; end
          protected :foo2
          private
          def self.bar; end
        end

        class MiddleYard < SuperYard
          def middle; end
        end

        class YARD < MiddleYard
          def mymethod; end
          def bar; end
        end

        module IncludedYard
          def foo; end
        end

        class FinalYard < SuperYard
          include IncludedYard
        end
      eof
    end

    it "should show inherited methods by default" do
      meths = P(:YARD).meths
      expect(meths).to include(P("YARD#mymethod"))
      expect(meths).to include(P("SuperYard#foo"))
      expect(meths).to include(P("SuperYard#foo2"))
      expect(meths).to include(P("SuperYard.bar"))
    end

    it "should allow :inherited to be set to false" do
      meths = P(:YARD).meths(:inherited => false)
      expect(meths).to include(P("YARD#mymethod"))
      expect(meths).to_not include(P("SuperYard#foo"))
      expect(meths).to_not include(P("SuperYard#foo2"))
      expect(meths).to_not include(P("SuperYard.bar"))
    end

    it "should not show overridden methods" do
      meths = P(:YARD).meths
      expect(meths).to include(P("YARD#bar"))
      expect(meths).to_not include(P("SuperYard#bar"))

      meths = P(:YARD).inherited_meths
      expect(meths).to_not include(P("YARD#bar"))
      expect(meths).to_not include(P("YARD#mymethod"))
      expect(meths).to include(P("SuperYard#foo"))
      expect(meths).to include(P("SuperYard#foo2"))
      expect(meths).to include(P("SuperYard.bar"))
    end

    it "should not show inherited methods overridden by other subclasses" do
      meths = P(:YARD).inherited_meths
      expect(meths).to include(P('MiddleYard#middle'))
      expect(meths).to_not include(P('SuperYard#middle'))
    end

    it "should show mixed in methods before superclass method" do
      meths = P(:FinalYard).meths
      expect(meths).to include(P('IncludedYard#foo'))
      expect(meths).to_not include(P('SuperYard#foo'))
    end
  end

  describe "#constants / #inherited_constants" do
    before(:all) do
      Registry.clear

      Parser::SourceParser.parse_string <<-eof
        class YARD
          CONST1 = 1
          CONST2 = "hello"
          CONST4 = 0
        end

        class SUPERYARD < YARD
          CONST4 = 5
        end

        class SubYard < SUPERYARD
          CONST2 = "hi"
          CONST3 = "foo"
        end
      eof
    end

    it "should list inherited constants by default" do
      consts = P(:SubYard).constants
      expect(consts).to include(P("YARD::CONST1"))
      expect(consts).to include(P("SubYard::CONST3"))

      consts = P(:SubYard).inherited_constants
      expect(consts).to include(P("YARD::CONST1"))
      expect(consts).to_not include(P("YARD::CONST2"))
      expect(consts).to_not include(P("SubYard::CONST2"))
      expect(consts).to_not include(P("SubYard::CONST3"))
    end

    it "should not list inherited constants if turned off" do
      consts = P(:SubYard).constants(:inherited => false)
      expect(consts).to_not include(P("YARD::CONST1"))
      expect(consts).to include(P("SubYard::CONST3"))
    end

    it "should not include an inherited constant if it is overridden by the object" do
      consts = P(:SubYard).constants
      expect(consts).to include(P("SubYard::CONST2"))
      expect(consts).to_not include(P("YARD::CONST2"))
    end

    it "should not include an inherited constant if it is overridden by another subclass" do
      consts = P(:SubYard).inherited_constants
      expect(consts).to include(P("SUPERYARD::CONST4"))
      expect(consts).to_not include(P("YARD::CONST4"))
    end

    it "should not set a superclass on BasicObject class" do
      o = ClassObject.new(:root, :Object)
      expect(o.superclass).to eq P(:BasicObject)
    end

    it "should set superclass of Object to BasicObject" do
      o = ClassObject.new(:root, :BasicObject)
      expect(o.superclass).to be_nil
    end

    it "should raise ArgumentError if superclass == self" do
      expect(lambda do
        o = ClassObject.new(:root, :Object) do |o|
          o.superclass = :Object
        end
      end).to raise_error(ArgumentError)
    end

    it "should tell the world if it is an exception class" do
      o = ClassObject.new(:root, :MyClass)
      o2 = ClassObject.new(:root, :OtherClass)
      o2.superclass = :SystemCallError
      o3 = ClassObject.new(:root, :StandardError)
      o3.superclass = :Object
      o4 = ClassObject.new(:root, :Object)

      o.superclass = :Object
      expect(o.is_exception?).to eq false

      o.superclass = :Exception
      expect(o.is_exception?).to eq true

      o.superclass = :NoMethodError
      expect(o.is_exception?).to eq true

      o.superclass = o2
      expect(o.is_exception?).to eq true

      o.superclass = o3
      expect(o.is_exception?).to eq true
    end

    it "should not raise ArgumentError if superclass is proxy in different namespace" do
      expect(lambda do
        o = ClassObject.new(:root, :X) do |o|
          o.superclass = P('OTHER::X')
        end
      end).to_not raise_error(ArgumentError)
    end
  end
end
