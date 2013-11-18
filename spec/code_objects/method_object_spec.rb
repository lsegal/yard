require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::MethodObject do
  before do
    Registry.clear
    @yard = ModuleObject.new(:root, :YARD)
  end

  it "should have a path of testing for an instance method in the root" do
    meth = MethodObject.new(:root, :testing)
    expect(meth.path).to eq "#testing"
  end

  it "should have a path of YARD#testing for an instance method in YARD" do
    meth = MethodObject.new(@yard, :testing)
    expect(meth.path).to eq "YARD#testing"
  end

  it "should have a path of YARD.testing for a class method in YARD" do
    meth = MethodObject.new(@yard, :testing, :class)
    expect(meth.path).to eq "YARD.testing"
  end

  it "should have a path of ::testing (note the ::) for a class method added to root namespace" do
    meth = MethodObject.new(:root, :testing, :class)
    expect(meth.path).to eq "::testing"
  end

  it "should exist in the registry after successful creation" do
    obj = MethodObject.new(@yard, :something, :class)
    expect(Registry.at("YARD.something")).to_not be_nil
    expect(Registry.at("YARD#something")).to be_nil
    expect(Registry.at("YARD::something")).to be_nil
    obj = MethodObject.new(@yard, :somethingelse)
    expect(Registry.at("YARD#somethingelse")).to_not be_nil
  end

  it "should allow #scope to be changed after creation" do
    obj = MethodObject.new(@yard, :something, :class)
    expect(Registry.at("YARD.something")).to_not be_nil
    obj.scope = :instance
    expect(Registry.at("YARD.something")).to be_nil
    expect(Registry.at("YARD#something")).to_not be_nil
  end

  it "should create object in :class scope if scope is :module" do
    obj = MethodObject.new(@yard, :module_func, :module)
    expect(obj.scope).to eq :class
    expect(obj.visibility).to eq :public
    expect(Registry.at('YARD.module_func')).to_not be_nil
  end

  it "should create second private instance method if scope is :module" do
    MethodObject.new(@yard, :module_func, :module)
    obj = Registry.at('YARD#module_func')
    expect(obj).to_not be_nil
    expect(obj.visibility).to eq :private
    expect(obj.scope).to eq :instance
  end

  it "should yield block to second method if scope is :module" do
    MethodObject.new(@yard, :module_func, :module) do |o|
      o.docstring = 'foo'
    end
    expect(Registry.at('YARD.module_func').docstring).to eq 'foo'
    expect(Registry.at('YARD#module_func').docstring).to eq 'foo'
  end

  describe '#name' do
    it "should show a prefix for an instance method when prefix=true" do
      obj = MethodObject.new(nil, :something)
      expect(obj.name(true)).to eq "#something"
    end

    it "should never show a prefix for a class method" do
      obj = MethodObject.new(nil, :something, :class)
      expect(obj.name).to eq :"something"
      expect(obj.name(true)).to eq "something"
    end
  end

  describe '#is_attribute?' do
    it "should only return true if attribute is set in namespace for read/write" do
      obj = MethodObject.new(@yard, :foo)
      @yard.attributes[:instance][:foo] = {:read => obj, :write => nil}
      expect(obj.is_attribute?).to be_true
      expect(MethodObject.new(@yard, :foo=).is_attribute?).to be_false
    end
  end

  describe '#attr_info' do
    it "should return attribute info if namespace is available" do
      obj = MethodObject.new(@yard, :foo)
      @yard.attributes[:instance][:foo] = {:read => obj, :write => nil}
      expect(obj.attr_info).to eq @yard.attributes[:instance][:foo]
    end

    it "should return nil if namespace is proxy" do
      obj = MethodObject.new(P(:ProxyClass), :foo)
      expect(MethodObject.new(@yard, :foo).attr_info).to eq nil
    end

    it "should return nil if meth is not an attribute" do
      expect(MethodObject.new(@yard, :notanattribute).attr_info).to eq nil
    end
  end

  describe '#writer?' do
    it "should return true if method is a writer attribute" do
      obj = MethodObject.new(@yard, :foo=)
      @yard.attributes[:instance][:foo] = {:read => nil, :write => obj}
      expect(obj.writer?).to eq true
      expect(MethodObject.new(@yard, :NOTfoo=).writer?).to eq false
    end
  end

  describe '#reader?' do
    it "should return true if method is a reader attribute" do
      obj = MethodObject.new(@yard, :foo)
      @yard.attributes[:instance][:foo] = {:read => obj, :write => nil}
      expect(obj.reader?).to eq true
      expect(MethodObject.new(@yard, :NOTfoo).reader?).to eq false
    end
  end

  describe '#constructor?' do
    before { @class = ClassObject.new(:root, :MyClass) }

    it "should mark the #initialize method as constructor" do
      MethodObject.new(@class, :initialize)
    end

    it "should not mark Klass.initialize as constructor" do
      expect(MethodObject.new(@class, :initialize, :class).constructor?).to be_false
    end

    it "should not mark module method #initialize as constructor" do
      expect(MethodObject.new(@yard, :initialize).constructor?).to be_false
    end
  end

  describe '#overridden_method' do
    before { Registry.clear }

    it "should return overridden method from mixin first" do
      YARD.parse_string(<<-eof)
        module C; def foo; end end
        class A; def foo; end end
        class B < A; include C; def foo; end end
      eof
      expect(Registry.at('B#foo').overridden_method).to eq Registry.at('C#foo')
    end

    it "should return overridden method from superclass" do
      YARD.parse_string(<<-eof)
        class A; def foo; end end
        class B < A; def foo; end end
      eof
      expect(Registry.at('B#foo').overridden_method).to eq Registry.at('A#foo')
    end

    it "should return nil if none is found" do
      YARD.parse_string(<<-eof)
        class A; end
        class B < A; def foo; end end
      eof
      expect(Registry.at('B#foo').overridden_method).to be_nil
    end

    it "should return nil if namespace is a proxy" do
      YARD.parse_string "def ARGV.foo; end"
      expect(Registry.at('ARGV.foo').overridden_method).to be_nil
    end
  end
end
