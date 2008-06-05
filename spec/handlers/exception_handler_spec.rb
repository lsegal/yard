require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ExceptionHandler do
  before { parse_file :exception_handler_001, __FILE__ }
  
  it "should not document an exception outside of a method" do
    P('Testing').has_tag?(:raise).should == false
  end
  
  it "should document a valid raise" do
    P('Testing#mymethod').tag(:raise).types.should == ['ArgumentError']
  end
  
  it "should only document non-dynamic raises" do
    P('Testing#mymethod2').tag(:raise).should be_nil
  end
  
  it "should not document a method with an existing @raise tag" do
    P('Testing#mymethod3').tag(:raise).types.should == ['A']
  end

  it "should only document the first raise message of a method (limitation of exception handler)" do
    P('Testing#mymethod4').tag(:raise).types.should == ['A']
  end
end