require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe YARD::Parser, "tag handling" do
  before { parse_file :tag_handler_001, __FILE__ }

  it "should know the list of all available tags" do
    expect(P("Foo#foo").tags).to include(P("Foo#foo").tag(:api))
  end

  it "should know the text of tags on a method" do
    expect(P("Foo#foo").tag(:api).text).to eq "public"
  end

  it "should return true when asked whether a tag exists" do
    expect(P("Foo#foo").has_tag?(:api)).to eq true
  end

end
