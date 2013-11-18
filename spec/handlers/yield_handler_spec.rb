require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}YieldHandler" do
  before(:all) { parse_file :yield_handler_001, __FILE__ }

  it "should only parse yield blocks in methods" do
    expect(P(:Testing).tag(:yield)).to be_nil
    expect(P(:Testing).tag(:yieldparam)).to be_nil
  end

  it "should handle an empty yield statement" do
    expect(P('Testing#mymethod').tag(:yield)).to be_nil
    expect(P('Testing#mymethod').tag(:yieldparam)).to be_nil
  end

  it "should not document a yield statement in a method with either @yield or @yieldparam" do
    expect(P('Testing#mymethod2').tag(:yield).types).to eq ['a', 'b']
    expect(P('Testing#mymethod2').tag(:yield).text).to eq "Blah"
    expect(P('Testing#mymethod2').tags(:yieldparam).size).to eq 2

    expect(P('Testing#mymethod3').tag(:yield).types).to eq ['a', 'b']
    expect(P('Testing#mymethod3').tags(:yieldparam).size).to eq 0

    expect(P('Testing#mymethod4').tag(:yieldparam).name).to eq '_self'
    expect(P('Testing#mymethod4').tag(:yieldparam).text).to eq 'BLAH'
  end

  it "should handle any arbitrary yield statement" do
    expect(P('Testing#mymethod5').tag(:yield).types).to eq [':a', 'b', '_self', 'File.read(\'file\', \'w\')', 'CONSTANT']
  end

  it "should handle parentheses" do
    expect(P('Testing#mymethod6').tag(:yield).types).to eq ['b', 'a']
  end

  it "should only document the first yield statement in a method (limitation of yield handler)" do
    expect(P('Testing#mymethod7').tag(:yield).types).to eq ['a']
  end

  it "should handle `self` keyword and list object type as yieldparam for _self" do
    expect(P('Testing#mymethod8').tag(:yield).types).to eq ['_self']
    expect(P('Testing#mymethod8').tag(:yieldparam).types).to eq ['Testing']
    expect(P('Testing#mymethod8').tag(:yieldparam).text).to eq "the object that the method was called on"
  end

  it "should handle `super` keyword and document it under _super" do
    expect(P('Testing#mymethod9').tag(:yield).types).to eq ['_super']
    expect(P('Testing#mymethod9').tag(:yieldparam).types).to be_nil
    expect(P('Testing#mymethod9').tag(:yieldparam).text).to eq "the result of the method from the superclass"
  end
end