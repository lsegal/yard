require File.dirname(__FILE__) + '/../../spec_helper'

module YARD::Templates::Helpers::MarkupHelper
  public :load_markup_provider, :markup_class, :markup_provider
end

class MyMock
  attr_accessor :options
  include YARD::Templates::Helpers::MarkupHelper
end

describe YARD::Templates::Helpers::MarkupHelper do
  before do
    @gen = mock('Generator')
    @gen.extend(YARD::Templates::Helpers::MarkupHelper)
  end
  
  def generator_should_exit
    STDERR.should_receive(:puts)
    @gen.should_receive(:exit)
  end
  
  it "should exit on an invalid markup type" do
    generator_should_exit
    @gen.stub!(:options).and_return({:markup => :invalid})
    
    # it will raise since providers == nil
    # but in reality it would have already `exit`ed.
    @gen.load_markup_provider rescue nil 
  end

  it "should exit on when an invalid markup provider is specified" do
    generator_should_exit
    @gen.stub!(:options).and_return({:markup => :markdown, :markup_provider => :invalid})
    
    # it will raise since providers == nil
    # but in reality it would have already `exit`ed.
    @gen.load_markup_provider rescue nil
    @gen.markup_class.should == nil
  end
  
  it "should load nothing if rdoc is specified" do
    @gen.stub!(:options).and_return({:markup => :rdoc})
    @gen.load_markup_provider
    @gen.markup_class.should == YARD::Templates::Helpers::MarkupHelper::SimpleMarkup
  end
  
  it "should search through available markup providers for the markup type if none is set" do
    @gen.should_receive(:require).with('bluecloth').and_return(true)
    @gen.stub!(:options).and_return({:markup => :markdown})
    # this only raises an exception because we mock out require to avoid 
    # loading any libraries but our implementation tries to return the library 
    # name as a constant
    @gen.load_markup_provider rescue nil
    @gen.markup_provider.should == :bluecloth
  end
  
  it "should continue searching if some of the providers are unavailable" do
    @gen.should_receive(:require).with('bluecloth').and_raise(LoadError)
    @gen.should_receive(:require).with('maruku').and_raise(LoadError)
    @gen.should_receive(:require).with('rpeg-markdown').and_return(true)
    @gen.stub!(:options).and_return({:markup => :markdown})
    # this only raises an exception because we mock out require to avoid 
    # loading any libraries but our implementation tries to return the library 
    # name as a constant
    @gen.load_markup_provider rescue nil
    @gen.markup_provider.should == :"rpeg-markdown"
  end
  
  it "should override the search if `:markup_provider` is set in options" do
    @gen.should_receive(:require).with('rdiscount').and_return(true)
    @gen.stub!(:options).and_return({:markup => :markdown, :markup_provider => :rdiscount})
    @gen.load_markup_provider rescue nil
    @gen.markup_provider.should == :rdiscount
  end

  it "should fail if no provider is found" do
    generator_should_exit
    YARD::Templates::Helpers::MarkupHelper::MARKUP_PROVIDERS[:markdown].each do |p|
      @gen.should_receive(:require).with(p[:lib].to_s).and_raise(LoadError)
    end
    @gen.stub!(:options).and_return({:markup => :markdown})
    @gen.load_markup_provider rescue nil
    @gen.markup_provider.should == nil
  end

  it "should fail if overridden provider is not found" do
    generator_should_exit
    @gen.should_receive(:require).with('rdiscount').and_raise(LoadError)
    @gen.stub!(:options).and_return({:markup => :markdown, :markup_provider => :rdiscount})
    @gen.load_markup_provider rescue nil
    @gen.markup_provider.should == nil
  end
end
