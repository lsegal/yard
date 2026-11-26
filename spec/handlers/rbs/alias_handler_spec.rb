# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::AliasHandler do
  before do
    parse_rbs <<-RBS
class List
  # Maps the list.
  def map: () -> Array[untyped]
  alias collect map

  def self.build: () -> List
  alias self.make self.build
end

interface _Each
  def each: () -> void
  alias each_item each
end
    RBS
  end

  it "registers an instance method alias" do
    obj = Registry.at('List#collect')
    expect(obj).to be_a(CodeObjects::MethodObject)
    expect(obj).to be_is_alias
    expect(Registry.at('List').aliases[obj]).to eq :map
  end

  it "registers a class method alias" do
    obj = Registry.at('List.make')
    expect(obj).to be_is_alias
    expect(Registry.at('List').aliases[obj]).to eq :build
  end

  it "registers an alias in an interface" do
    expect(Registry.at('_Each#each_item')).to be_is_alias
  end

  it "copies the aliased method's docstring and tags" do
    obj = Registry.at('List#collect')
    expect(obj.docstring).to eq 'Maps the list.'
    expect(obj.tag(:return).types).to eq Registry.at('List#map').tag(:return).types
  end
end
