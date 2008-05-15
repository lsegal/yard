require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::VisibilityHandler do
  before { parse_file :tag_handler_001, __FILE__ }
  
  it "should know the list of all available tags" do
    Registry.at("Foo#foo").tags.should include(Registry.at("Foo#foo").tag(:api))
  end
  
  it "should know the text of tags on a method" do
    Registry.at("Foo#foo").tag(:api).text.should == "public"
  end
  
  it "should return true when asked whether a tag exists" do
    Registry.at("Foo#foo").has_tag?(:api).should == true
  end
  
end
