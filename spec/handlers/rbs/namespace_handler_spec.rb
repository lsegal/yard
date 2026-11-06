# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::NamespaceHandler do
  it "registers a class" do
    parse_rbs <<-RBS
class Foo
end
    RBS
    expect(Registry.at('Foo')).to be_a(CodeObjects::ClassObject)
  end

  it "registers a class with a docstring" do
    parse_rbs <<-RBS
# A simple class.
class Foo
end
    RBS
    expect(Registry.at('Foo').docstring).to eq 'A simple class.'
  end

  it "registers a class with a superclass" do
    parse_rbs <<-RBS
class Child < Parent
end
    RBS
    obj = Registry.at('Child')
    expect(obj).to be_a(CodeObjects::ClassObject)
    expect(obj.superclass.path).to eq 'Parent'
  end

  it "strips generic type params from superclass" do
    parse_rbs <<-RBS
class MyList < Array[String]
end
    RBS
    expect(Registry.at('MyList').superclass.path).to eq 'Array'
  end

  it "registers a module" do
    parse_rbs <<-RBS
module Helpers
end
    RBS
    expect(Registry.at('Helpers')).to be_a(CodeObjects::ModuleObject)
  end

  it "registers an interface as a module" do
    parse_rbs <<-RBS
interface _Stringable
end
    RBS
    expect(Registry.at('_Stringable')).to be_a(CodeObjects::ModuleObject)
  end

  it "registers nested namespaces" do
    parse_rbs <<-RBS
module Outer
  class Inner
  end
end
    RBS
    expect(Registry.at('Outer')).to be_a(CodeObjects::ModuleObject)
    expect(Registry.at('Outer::Inner')).to be_a(CodeObjects::ClassObject)
  end

  it "correctly handles a class with an inline comment" do
    parse_rbs <<-RBS
class Documented # This is a class
end
    RBS
    expect(Registry.at('Documented')).to be_a(CodeObjects::ClassObject)
  end

  it "closes a namespace at an end followed by an inline comment" do
    parse_rbs <<-RBS
module Outer
  class Inner
    def run: () -> void
  end # Inner

  def after: () -> void
end

class Top
end
    RBS
    expect(Registry.at('Outer#after')).to be_a(CodeObjects::MethodObject)
    expect(Registry.at('Outer::Inner#after')).to be_nil
    expect(Registry.at('Top')).to be_a(CodeObjects::ClassObject)
    expect(Registry.at('Outer::Top')).to be_nil
  end
end
