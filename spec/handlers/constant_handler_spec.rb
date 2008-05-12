require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ConstantHandler do
  before { parse_file :constant_handler_001, __FILE__ }
  
  it "should not parse constants inside methods" do
    Registry.at("A::B::SOMECONSTANT").source.should == "SOMECONSTANT= \"hello\""
  end
end