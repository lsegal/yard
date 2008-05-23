require File.dirname(__FILE__) + '/../spec_helper'
require 'stringio'

include YARD::Generators

describe YARD::Generators::Base, 'Section handling' do
  before { Registry.clear }
  
  it "should allow a list of sections to be returned by sections_for" do
    base = Generators::Base.new
    base.stub!(:sections_for).and_return([:meth1, :meth2, :meth3])
    base.should_receive(:meth1).and_return('a')
    base.should_receive(:meth2).and_return('b')
    base.should_receive(:meth3).and_return('c')
    base.generate(Registry.root).should == 'abc'
  end
  
  it "should allow a heirarchical list of sections to be returned by sections_for" do
    base = Generators::Base.new
    base.stub!(:sections_for).and_return([:meth1, [:meth2, :meth3]])
    base.should_receive(:meth1).and_return('a')
    base.should_not_receive(:meth2)
    base.should_not_receive(:meth3)
    base.generate(Registry.root).should == 'a'
  end    
  
  it "should yield sub section lists to the parent section" do
    class XYZ < Generators::Base
      def sections_for(object) [:meth1, [:submeth1, :submeth2, [:submeth1]]] end
      def meth1(object) object.name.to_s + yield(object) end
      def submeth1(object) object.name.to_s end
      def submeth2(object) object.name.to_s + yield(P(:YARD)) end
    end

    CodeObjects::Base.new(:root, :YARD)
    XYZ.new.generate(Registry.root).should == "rootrootrootYARD"
  end
end

describe YARD::Generators::Base, 'Rendering' do
  it "should have a default template path" do
    Generators::Base.template_paths.should == [YARD::TEMPLATE_ROOT]
  end
  
  it "should find the right erb file to render given a template, format and name" do
    base = Generators::Base.new
    file = File.join(YARD::TEMPLATE_ROOT, 'default', 'base', 'html', 'name.erb')
    File.should_receive(:file?).with(file).and_return(true)
    File.should_receive(:read).with(file).and_return("output")
    base.stub!(:sections_for).and_return([:name])
    base.generate(Registry.root).should == "output"
  end
    
  it "should allow the user to add extra search paths to find a custom template" do
    Generators::Base.register_template_path 'doc'
    base = Generators::Base.new
    file = File.join('doc', 'default', 'base', 'html', 'name.erb')
    File.should_receive(:file?).with(file).and_return(true)
    File.should_receive(:read).with(file).and_return("output")
    base.stub!(:sections_for).and_return([:name])
    base.generate(Registry.root).should == "output"
  end
end