require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}VisibilityHandler" do
  before(:all) { parse_file :visibility_handler_001, __FILE__ }

  it "should be able to set visibility to public" do
    expect(Registry.at("Testing#pub").visibility).to eq :public
    expect(Registry.at("Testing#pub2").visibility).to eq :public
  end

  it "should be able to set visibility to private" do
    expect(Registry.at("Testing#priv").visibility).to eq :private
  end

  it "should be able to set visibility to protected" do
    expect(Registry.at("Testing#prot").visibility).to eq :protected
  end

  it "should support parameters and only set visibility on those methods" do
    expect(Registry['Testing#notpriv'].visibility).to eq :protected
    expect(Registry['Testing#notpriv2'].visibility).to eq :protected
    expect(Registry['Testing#notpriv?'].visibility).to eq :protected
  end

  it "should only accept strings and symbols" do
    Registry.at('Testing#name').should be_nil
    Registry.at('Testing#argument').should be_nil
    Registry.at('Testing#method_call').should be_nil
  end

  it "should handle constants passed in as symbols" do
    expect(Registry.at('Testing#Foo').visibility).to eq :private
  end
end
