require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}ModuleHandler" do
  before(:all) { parse_file :module_handler_001, __FILE__ }

  it "should parse a module block" do
    expect(Registry.at(:ModName)).not_to eq nil
    expect(Registry.at("ModName::OtherModName")).not_to eq nil
  end

  it "should attach docstring" do
    expect(Registry.at("ModName::OtherModName").docstring).to eq "Docstring"
  end

  it "should handle any formatting" do
    expect(Registry.at(:StressTest)).not_to eq nil
  end

  it "should handle complex module names" do
    expect(Registry.at("A::B")).not_to eq nil
  end

  it "should handle modules in the form ::ModName" do
    Registry.at("Kernel").should_not be_nil
  end

  it "should list mixins in proper order" do
    expect(Registry.at('D').mixins).to eq [P(:C), P(:B), P(:A)]
  end

  it "should create proper module when constant is in namespace" do
    Registry.at('Q::FOO::A').should_not be_nil
  end
end
