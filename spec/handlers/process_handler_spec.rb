require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}ProcessHandler" do
  before(:all) { parse_file :process_handler_001, __FILE__ }

  it "should only work for classes that extend YARD::Handlers::*" do
    Registry.at('A#process').should be_nil
  end
  
  it "should work for process { }" do
    Registry.at('B#process').should_not be_nil
  end
  
  it "should work for process do ... end" do
    Registry.at('C#process').should_not be_nil
  end
end