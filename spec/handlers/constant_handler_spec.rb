require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}ConstantHandler" do
  before(:all) { parse_file :constant_handler_001, __FILE__ }

  it "should not parse constants inside methods" do
    expect(Registry.at("A::B::SOMECONSTANT").source).to eq "SOMECONSTANT= \"hello\""
  end

  it "should only parse valid constants" do
    Registry.at("A::B::notaconstant").should be_nil
  end

  it "should maintain newlines" do
    expect(Registry.at("A::B::MYCONSTANT").value.gsub("\r", "")).to eq "A +\nB +\nC +\nD"
  end

  it "should turn Const = Struct.new(:sym) into class Const with attr :sym" do
    obj = Registry.at("MyClass")
    obj.should be_kind_of(CodeObjects::ClassObject)
    attrs = obj.attributes[:instance]
    [:a, :b, :c].each do |key|
      attrs.should have_key(key)
      attrs[key][:read].should_not be_nil
      attrs[key][:write].should_not be_nil
    end
  end

  it "should turn Const = Struct.new('Name', :sym) into class Const with attr :sym" do
    obj = Registry.at("NotMyClass")
    obj.should be_kind_of(CodeObjects::ClassObject)
    attrs = obj.attributes[:instance]
    [:b, :c].each do |key|
      attrs.should have_key(key)
      attrs[key][:read].should_not be_nil
      attrs[key][:write].should_not be_nil
    end

    Registry.at("NotMyClass2").should be_nil
  end

  it "should turn Const = Struct.new into empty struct" do
    obj = Registry.at("MyEmptyStruct")
    obj.should_not be_nil
    obj.attributes[:instance].should be_empty
  end

  it "should maintain docstrings on structs defined via constants" do
    obj = Registry.at("DocstringStruct")
    obj.should_not be_nil
    expect(obj.docstring).to eq "A crazy struct."
    obj.attributes[:instance].should_not be_empty
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
