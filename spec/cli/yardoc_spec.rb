require File.dirname(__FILE__) + '/../spec_helper'

class YARD::CLI::Yardoc; public :optparse end

describe YARD::CLI::Yardoc do
  before do
    @yardoc = YARD::CLI::Yardoc.new
    @yardoc.stub!(:generate).and_return(false)
    Registry.instance.stub!(:load)
  end
  
  it "should select a markup provider when --markup-provider or -mp is set" do
    @yardoc.optparse("-M", "test")
    @yardoc.options[:markup_provider].should == :test
    @yardoc.optparse("--markup-provider", "test2")
    @yardoc.options[:markup_provider].should == :test2
  end
  
  it "should search for and use yardopts file specified by #options_file" do
    IO.should_receive(:read).with("test").and_return("-o \n\nMYPATH\nFILE1 FILE2")
    @yardoc.stub!(:support_rdoc_document_file!).and_return([])
    @yardoc.options_file = "test"
    @yardoc.run
    @yardoc.options[:serializer].options[:basepath].should == :MYPATH
    @yardoc.files.should == ["FILE1", "FILE2"]
  end
  
  it "should allow opts specified in command line to override yardopts file" do
    IO.should_receive(:read).with(".yardopts").and_return("-o NOTMYPATH")
    @yardoc.stub!(:support_rdoc_document_file!).and_return([])
    @yardoc.run("-o", "MYPATH", "FILE")
    @yardoc.options[:serializer].options[:basepath].should == :MYPATH
    @yardoc.files.should == ["FILE"]
  end
  
  it "should load the RDoc .document file if found" do
    IO.should_receive(:read).with(".yardopts").and_return("-o NOTMYPATH")
    @yardoc.stub!(:support_rdoc_document_file!).and_return(["FILE2", "FILE3"])
    @yardoc.run("-o", "MYPATH", "FILE1")
    @yardoc.options[:serializer].options[:basepath].should == :MYPATH
    @yardoc.files.should == ["FILE1", "FILE2", "FILE3"]
  end
end