require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}ClassConditionHandler" do
  before do
    Registry.clear 
    parse_file :class_condition_handler_001, __FILE__
  end
  
  def verify_method(*names)
    names.each {|name| Registry.at("A##{name}").should_not be_nil }
  end
  
  it "should parse all if/elsif blocks regardless of condition" do
    verify_method :a, :b, :c, :d
  end
  
  it "should parse all unless blocks regardless of condition" do
    verify_method :e, :f, :g
  end
  
  it "should not parse conditionals inside methods" do
    Registry.at('A#i').should be_nil
  end
end if RUBY19