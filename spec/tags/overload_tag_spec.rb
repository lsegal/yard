require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Tags::OverloadTag do
  before do
    @tag = Tags::OverloadTag.new(:overload, <<-'eof')
      def bar(a, b = 1, &block)
        Hello world
        @param a [String]
        @return [String]
    eof
  end

  it "should parse the first line as a method signature" do
    expect(@tag.signature).to eq "def bar(a, b = 1, &block)"
    expect(@tag.parameters).to eq [['a', nil], ['b', "1"], ['&block', nil]]
  end

  it "should parse the rest of the text as a new Docstring" do
    expect(@tag.docstring).to be_instance_of(Docstring)
    expect(@tag.docstring).to eq "Hello world"
  end

  it "should set Docstring's object after #object= is called" do
    m = mock(:object)
    @tag.object = m
    expect(@tag.docstring.object).to eq m
  end

  it "should respond to #tag, #tags and #has_tag?" do
    @tag.object = mock(:object)
    expect(@tag.tags.size).to eq 2
    expect(@tag.tag(:param).name).to eq "a"
    expect(@tag.has_tag?(:return)).to eq true
  end

  it "should not be a CodeObjects::Base when not hooked up to an object" do
    @tag.object = nil
    expect(@tag.is_a?(CodeObjects::Base)).to eq false
  end

  it "should be a CodeObjects::Base when hooked up to an object" do
    @tag.object = mock(:object)
    expect(@tag.object).to receive(:is_a?).at_least(3).times.with(CodeObjects::Base).and_return(true)
    expect(@tag.is_a?(CodeObjects::Base)).to eq true
    expect(@tag.kind_of?(CodeObjects::Base)).to eq true
    expect((CodeObjects::Base === @tag)).to eq true
  end

  it "should not parse 'def' out of method name" do
    tag = Tags::OverloadTag.new(:overload, "default")
    expect(tag.signature).to eq "default"
  end
end
