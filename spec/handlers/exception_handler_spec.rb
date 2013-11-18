require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}ExceptionHandler" do
  before(:all) { parse_file :exception_handler_001, __FILE__ }

  it "should not document an exception outside of a method" do
    expect(P('Testing').has_tag?(:raise)).to eq false
  end

  it "should document a valid raise" do
    expect(P('Testing#mymethod').tag(:raise).types).to eq ['ArgumentError']
  end

  it "should only document non-dynamic raises" do
    expect(P('Testing#mymethod2').tag(:raise)).to be_nil
    expect(P('Testing#mymethod6').tag(:raise)).to be_nil
    expect(P('Testing#mymethod7').tag(:raise)).to be_nil
  end

  it "should treat ConstantName.new as a valid exception class" do
    expect(P('Testing#mymethod8').tag(:raise).types).to eq ['ExceptionClass']
  end

  it "should not document a method with an existing @raise tag" do
    expect(P('Testing#mymethod3').tag(:raise).types).to eq ['A']
  end

  it "should only document the first raise message of a method (limitation of exception handler)" do
    expect(P('Testing#mymethod4').tag(:raise).types).to eq ['A']
  end

  it "should handle complex class names" do
    expect(P('Testing#mymethod5').tag(:raise).types).to eq ['YARD::Parser::UndocumentableError']
  end

  it "should ignore any raise calls on a receiver" do
    expect(P('Testing#mymethod9').tag(:raise)).to be_nil
  end

  it "should handle raise expressions that are method calls" do
    expect(P('Testing#mymethod10').tag(:raise)).to be_nil
    expect(P('Testing#mymethod11').tag(:raise)).to be_nil
  end

  it "should ignore empty raise call" do
    expect(P('Testing#mymethod12').tag(:raise)).to be_nil
  end
end