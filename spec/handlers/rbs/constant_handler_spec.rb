# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::ConstantHandler do
  it "registers a constant" do
    parse_rbs <<-RBS
class Foo
  VERSION: String
end
    RBS
    expect(Registry.at('Foo::VERSION')).to be_a(CodeObjects::ConstantObject)
  end

  it "adds a @return tag with the RBS type" do
    parse_rbs <<-RBS
class Foo
  VERSION: String
end
    RBS
    obj = Registry.at('Foo::VERSION')
    expect(obj.tag(:return).types).to eq ['String']
  end

  it "registers top-level constants" do
    parse_rbs <<-RBS
VERSION: String
    RBS
    expect(Registry.at('VERSION')).to be_a(CodeObjects::ConstantObject)
  end

  it "preserves the docstring" do
    parse_rbs <<-RBS
class Foo
  # The current version.
  VERSION: String
end
    RBS
    expect(Registry.at('Foo::VERSION').docstring).to eq 'The current version.'
  end

  it "handles compound type for constant" do
    parse_rbs <<-RBS
class Foo
  ID: Integer | String
end
    RBS
    obj = Registry.at('Foo::ID')
    expect(obj.tag(:return).types).to include('Integer', 'String')
  end

  it "parses constants without space after colon" do
    parse_rbs <<-RBS
class Foo
  TIMEOUT:Integer
end
    RBS
    obj = Registry.at('Foo::TIMEOUT')
    expect(obj).to be_a(CodeObjects::ConstantObject)
    expect(obj.tag(:return).types).to eq ['Integer']
  end

  it "registers class and module aliases as constants" do
    parse_rbs <<-RBS
module Outer
  # A sequence.
  class Seq = Array
  module Enum = Enumerable

  def after: () -> void
end

class Top
end
    RBS
    seq = Registry.at('Outer::Seq')
    expect(seq).to be_a(CodeObjects::ConstantObject)
    expect(seq.value).to eq 'Array'
    expect(seq.docstring).to eq 'A sequence.'
    expect(Registry.at('Outer::Enum')).to be_a(CodeObjects::ConstantObject)
    expect(Registry.at('Outer::Enum').value).to eq 'Enumerable'
    expect(Registry.at('Outer#after')).to be_a(CodeObjects::MethodObject)
    expect(Registry.at('Top')).to be_a(CodeObjects::ClassObject)
  end
end
