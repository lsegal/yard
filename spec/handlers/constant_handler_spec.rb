require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}ConstantHandler" do
  before(:all) { parse_file :constant_handler_001, __FILE__ }

  it "should not parse constants inside methods" do
    expect(Registry.at("A::B::SOMECONSTANT").source).to eq "SOMECONSTANT= \"hello\""
  end

  it "should only parse valid constants" do
    expect(Registry.at("A::B::notaconstant")).to be_nil
  end

  it "should maintain newlines" do
    expect(Registry.at("A::B::MYCONSTANT").value.gsub("\r", "")).to eq "A +\nB +\nC +\nD"
  end

  it "should turn Const = Struct.new(:sym) into class Const with attr :sym" do
    obj = Registry.at("MyClass")
    expect(obj).to be_kind_of(CodeObjects::ClassObject)
    attrs = obj.attributes[:instance]
    [:a, :b, :c].each do |key|
      expect(attrs).to have_key(key)
      expect(attrs[key][:read]).to_not be_nil
      expect(attrs[key][:write]).to_not be_nil
    end
  end

  it "should turn Const = Struct.new('Name', :sym) into class Const with attr :sym" do
    obj = Registry.at("NotMyClass")
    expect(obj).to be_kind_of(CodeObjects::ClassObject)
    attrs = obj.attributes[:instance]
    [:b, :c].each do |key|
      expect(attrs).to have_key(key)
      expect(attrs[key][:read]).to_not be_nil
      expect(attrs[key][:write]).to_not be_nil
    end

    expect(Registry.at("NotMyClass2")).to be_nil
  end

  it "should turn Const = Struct.new into empty struct" do
    obj = Registry.at("MyEmptyStruct")
    expect(obj).to_not be_nil
    expect(obj.attributes[:instance]).to be_empty
  end

  it "should maintain docstrings on structs defined via constants" do
    obj = Registry.at("DocstringStruct")
    expect(obj).to_not be_nil
    expect(obj.docstring).to eq "A crazy struct."
    expect(obj.attributes[:instance]).to_not be_empty
    a1 = Registry.at("DocstringStruct#bar")
    a2 = Registry.at("DocstringStruct#baz")
    expect(a1.docstring).to eq "An attr"
    expect(a1.tag(:return).types).to eq ["String"]
    expect(a2.docstring).to eq "Another attr"
    expect(a2.tag(:return).types).to eq ["Number"]
  end

  it "should raise undocumentable error in 1.9 parser for Struct.new assignment to non-const" do
    undoc_error "nonconst = Struct.new"
  end unless LEGACY_PARSER
end