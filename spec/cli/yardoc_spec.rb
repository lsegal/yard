require File.dirname(__FILE__) + '/../spec_helper'

class YARD::CLI::Yardoc; public :optparse end

describe YARD::CLI::Yardoc do
  before do
    @yardoc = YARD::CLI::Yardoc.new
    @yardoc.stub!(:generate).and_return(false)
    Registry.instance.stub!(:load)
  end
  
  it "should accept --title" do
    @yardoc.optparse('--title', 'hello world')
    @yardoc.options[:title].should == :'hello world'
  end

  it "should alias --main to the --readme flag" do
    readme = File.join(File.dirname(__FILE__),'..','..','README.markdown')

    @yardoc.optparse('--main', readme)
    @yardoc.options[:readme].should == readme.to_sym
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
  
  it "should accept extra files if specified after '-' with source files" do
    File.should_receive(:file?).with('extra_file1').and_return(true)
    File.should_receive(:file?).with('extra_file2').and_return(true)
    @yardoc.optparse *%w( file1 file2 - extra_file1 extra_file2 )
    @yardoc.files.should == %w( file1 file2 )
    @yardoc.options[:files].should == %w( extra_file1 extra_file2 )
  end
  
  it "should accept files section only containing extra files" do
    @yardoc.optparse *%w( - LICENSE )
    @yardoc.files.should == %w( lib/**/*.rb )
    @yardoc.options[:files].should == %w( LICENSE )
  end

  it "should accept globs as extra files" do
    Dir.should_receive(:glob).with('README*').and_return []
    Dir.should_receive(:glob).with('*.txt').and_return ['a.txt', 'b.txt']
    File.should_receive(:file?).with('a.txt').and_return(true)
    File.should_receive(:file?).with('b.txt').and_return(true)
    @yardoc.optparse *%w( file1 file2 - *.txt )
    @yardoc.files.should == %w( file1 file2 )
    @yardoc.options[:files].should == %w( a.txt b.txt )
  end
  
  it "should accept no params and parse lib/**/*.rb" do
    @yardoc.optparse
    @yardoc.files.should == %w( lib/**/*.rb )
  end
  
  it "should accept a --query" do
    @yardoc.optparse *%w( --query @return )
    @yardoc.options[:verifier].should be_a(Verifier)
  end
  
  it "should accept multiple --query arguments" do
    obj = mock(:object)
    obj.should_receive(:tag).ordered.with('return').and_return(true)
    obj.should_receive(:tag).ordered.with('tag').and_return(false)
    @yardoc.optparse *%w( --query @return --query @tag )
    @yardoc.options[:verifier].should be_a(Verifier)
    @yardoc.options[:verifier].call(obj).should == false
  end
end
