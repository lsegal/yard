require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Generators::Base, 'Section handling' do
  it "should allow a list of sections to be returned by sections_for"
  it "should allow a heirarchical list of sections to be returned by sections_for"
  it "should yield sub section lists to the parent section"
end

describe YARD::Generators::Base, 'Rendering' do
  it "should find the right erb file to render given a template, format and name"
  it "should allow the user to add extra search paths to find a custom template"
end