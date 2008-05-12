require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ClassVariableHandler do
  before { parse_file :class_variable_handler_001, __FILE__ }
  
  it "should not parse class variables inside methods" do
    Registry.at("A::B::@@somevar").source.should == "@@somevar = \"hello\""
  end
end