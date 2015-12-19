require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}ConstantHandler" do
  before(:all) { parse_file :constant_handler_001, __FILE__ }

  it "does not parse constants inside methods" do
    expect(Registry.at("A::B::SOMECONSTANT").source).to eq "SOMECONSTANT= \"hello\""
  end

  it "only parses valid constants" do
    expect(Registry.at("A::B::notaconstant")).to be nil
  end

  it "maintains newlines" do
    expect(Registry.at("A::B::MYCONSTANT").value.gsub("\r", "")).to eq "A +\nB +\nC +\nD"
  end

  it "turns Const = Struct.new(:sym) into class Const with attr :sym" do
    obj = Registry.at("MyClass")
    expect(obj).to be_kind_of(CodeObjects::ClassObject)
    attrs = obj.attributes[:instance]
    [:a, :b, :c].each do |key|
      expect(attrs).to have_key(key)
      expect(attrs[key][:read]).not_to be nil
      expect(attrs[key][:write]).not_to be nil
    end
  end

  it "turns Const = Struct.new('Name', :sym) into class Const with attr :sym" do
    obj = Registry.at("NotMyClass")
    expect(obj).to be_kind_of(CodeObjects::ClassObject)
    attrs = obj.attributes[:instance]
    [:b, :c].each do |key|
      expect(attrs).to have_key(key)
      expect(attrs[key][:read]).not_to be nil
      expect(attrs[key][:write]).not_to be nil
    end

    expect(Registry.at("NotMyClass2")).to be nil
  end

  it "turns Const = Struct.new into empty struct" do
    obj = Registry.at("MyEmptyStruct")
    expect(obj).not_to be nil
    expect(obj.attributes[:instance]).to be_empty
  end

  it "maintains docstrings on structs defined via constants" do
    obj = Registry.at("DocstringStruct")
    expect(obj).not_to be nil
    expect(obj.docstring).to eq "A crazy struct."
    expect(obj.attributes[:instance]).not_to be_empty
    a1 = Registry.at("DocstringStruct#bar")
    a2 = Registry.at("DocstringStruct#baz")
    expect(a1.docstring).to eq "An attr"
    expect(a1.tag(:return).types).to eq ["String"]
    expect(a2.docstring).to eq "Another attr"
    expect(a2.tag(:return).types).to eq ["Number"]
    a3 = Registry.at("DocstringStruct#new_syntax")
    expect(a3.docstring).to eq "Attribute defined with the new syntax"
    expect(a3.tag(:return).types).to eq ["Symbol"]
  end

  it "raises undocumentable error in 1.9 parser for Struct.new assignment to non-const" do
    undoc_error "nonconst = Struct.new"
  end unless LEGACY_PARSER
end