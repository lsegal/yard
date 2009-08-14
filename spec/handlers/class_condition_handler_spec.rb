require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}ClassConditionHandler" do
  before(:all) { parse_file :class_condition_handler_001, __FILE__ }
  
  def verify_method(*names)
    names.each {|name| Registry.at("A##{name}").should_not be_nil }
    names.each {|name| Registry.at("A##{name}not").should be_nil }
  end
  
  it "should parse all if/elsif blocks for complex conditions" do
    verify_method :a, :b, :c, :d
  end
  
  it "should parse all unless blocks for complex conditions" do
    verify_method :g
  end
  
  it "should not parse conditionals inside methods" do
    verify_method :h
  end
  
  it "should only parse then block if condition is literal value `true`" do
    verify_method :p
  end
  
  it "should only parse else block if condition is literal value `false`" do
    verify_method :q
  end

  it "should only parse then block if condition is literal integer != 0" do
    verify_method :o
  end

  it "should only parse else block if condition is literal integer == 0" do
    verify_method :n
  end
  
  it "should invert block to parse for literal condition if it's an unless block" do
    verify_method :e
  end
  
  it "should handle conditions such as 'defined? VALUE'" do
    verify_method :j, :k
  end
end if RUBY19