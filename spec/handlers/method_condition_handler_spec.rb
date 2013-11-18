require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}MethodConditionHandler" do
  before(:all) { parse_file :method_condition_handler_001, __FILE__ }

  it "should not parse regular if blocks in methods" do
    expect(Registry.at('#b')).to be_nil
  end

  it "should parse if/unless blocks in the form X if COND" do
    expect(Registry.at('#c')).to_not be_nil
    expect(Registry.at('#d')).to_not be_nil
  end
end