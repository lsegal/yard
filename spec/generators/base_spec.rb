require File.dirname(__FILE__) + '/../spec_helper'
require 'stringio'

include YARD::Generators

describe YARD::Generators::Base, 'Section handling' do
  it "should allow a list of sections to be returned by sections_for"
  it "should allow a heirarchical list of sections to be returned by sections_for"
  it "should yield sub section lists to the parent section"
end

describe YARD::Generators::Base, 'Rendering' do
  it "should have a default template path" do
    Generators::Base.template_paths.should == [YARD::TEMPLATE_ROOT]
  end
  
  it "should find the right erb file to render given a template, format and name" do
    base = Generators::Base.new
    file = File.join(YARD::TEMPLATE_ROOT, 'default', 'base', 'html', 'name.erb')
    File.should_receive(:file?).with(file).and_return(true)
    File.should_receive(:read).with(file).and_return("")
    base.stub!(:sections_for).and_return([:name])
    base.generate(Registry.root)
  end
    
  it "should allow the user to add extra search paths to find a custom template"
end