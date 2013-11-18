require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}AttributeHandler" do
  before(:all) { parse_file :attribute_handler_001, __FILE__ }

  def read_write(namespace, name, read, write, scope = :instance)
    rname, wname = namespace.to_s+"#"+name.to_s, namespace.to_s+"#"+name.to_s+"="
    if read
      expect(Registry.at(rname)).to be_instance_of(CodeObjects::MethodObject)
    else
      expect(Registry.at(rname)).to eq nil
    end

    if write
      expect(Registry.at(wname)).to be_kind_of(CodeObjects::MethodObject)
    else
      expect(Registry.at(wname)).to eq nil
    end

    attrs = Registry.at(namespace).attributes[scope][name]
    expect(attrs[:read]).to eq (read ? Registry.at(rname) : nil)
    expect(attrs[:write]).to eq (write ? Registry.at(wname) : nil)
  end

  it "should parse attributes inside modules too" do
    expect(Registry.at("A#x=")).to_not eq nil
  end

  it "should parse 'attr'" do
    read_write(:B, :a, true, true)
    read_write(:B, :a2, true, false)
    read_write(:B, "a3", true, false)
  end

  it "should parse 'attr_reader'" do
    read_write(:B, :b, true, false)
  end

  it "should parse 'attr_writer'" do
    read_write(:B, :e, false, true)
  end

  it "should parse 'attr_accessor'" do
    read_write(:B, :f, true, true)
  end

  it "should parse a list of attributes" do
    read_write(:B, :b, true, false)
    read_write(:B, :c, true, false)
    read_write(:B, :d, true, false)
  end

  it "should have a default docstring if one is not supplied" do
    expect(Registry.at("B#f=").docstring).to_not be_empty
  end

  it "should set the correct docstring if one is supplied" do
    expect(Registry.at("B#b").docstring).to eq "Docstring"
    expect(Registry.at("B#c").docstring).to eq "Docstring"
    expect(Registry.at("B#d").docstring).to eq "Docstring"
  end

  it "should be able to differentiate between class and instance attributes" do
    expect(P('B').class_attributes[:z][:read].scope).to eq :class
    expect(P('B').instance_attributes[:z][:read].scope).to eq :instance
  end

  it "should respond true in method's #is_attribute?" do
    expect(P('B#a').is_attribute?).to eq true
    expect(P('B#a=').is_attribute?).to eq true
  end

  it "should not return true for #is_explicit? in created methods" do
    Registry.at(:B).meths.each do |meth|
      expect(meth.is_explicit?).to eq false
    end
  end

  it "should handle attr call with no arguments" do
    expect{ StubbedSourceParser.parse_string "attr" }.to_not raise_error
  end

  it "should add existing reader method as part of attr_writer combo" do
    expect(Registry.at('C#foo=').attr_info[:read]).to eq Registry.at('C#foo')
  end

  it "should add existing writer method as part of attr_reader combo" do
    expect(Registry.at('C#foo').attr_info[:write]).to eq Registry.at('C#foo=')
  end

  it "should maintain visibility for attr_reader" do
    expect(Registry.at('D#parser').visibility).to eq :protected
  end
end
