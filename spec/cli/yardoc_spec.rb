require File.dirname(__FILE__) + '/../spec_helper'

class YARD::CLI::Yardoc; public :optparse end

describe YARD::CLI::Yardoc do
  before do
    @yardoc = YARD::CLI::Yardoc.new
    @yardoc.stub!(:generate).and_return(false)
    Templates::Engine.stub!(:render)
    Templates::Engine.stub!(:generate)
    YARD.stub!(:parse)
  end
  
  it "should accept --title" do
    @yardoc.optparse('--title', 'hello world')
    @yardoc.options[:title].should == 'hello world'
  end

  it "should alias --main to the --readme flag" do
    readme = File.join(File.dirname(__FILE__),'..','..','README.md')

    @yardoc.optparse('--main', readme)
    @yardoc.options[:readme].should == readme
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

  it "should use String#shell_split to split .yardopts tokens" do
    optsdata = "foo bar"
    optsdata.should_receive(:shell_split)
    IO.should_receive(:read).with("test").and_return(optsdata)
    @yardoc.stub!(:support_rdoc_document_file!).and_return([])
    @yardoc.options_file = "test"
    @yardoc.run
  end
  
  it "should allow --title to have multiple spaces in .yardopts" do
    IO.should_receive(:read).with("test").and_return("--title \"Foo Bar\"")
    @yardoc.stub!(:support_rdoc_document_file!).and_return([])
    @yardoc.options_file = "test"
    @yardoc.run
    @yardoc.options[:title].should == "Foo Bar"
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
    @yardoc.files.should == %w( lib/**/*.rb ext/**/*.c )
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
  
  it "should accept no params and parse lib/**/*.rb ext/**/*.c" do
    @yardoc.optparse
    @yardoc.files.should == %w( lib/**/*.rb ext/**/*.c )
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
  
  it "should accept --no-private" do
    obj = mock(:object)
    obj.should_receive(:tag).ordered.with('private').and_return(true)
    @yardoc.optparse *%w( --no-private )
    @yardoc.options[:verifier].call(obj).should == false
  end
  
  it "should accept --default-return" do
    @yardoc.optparse *%w( --default-return XYZ )
    @yardoc.options[:default_return].should == "XYZ"
  end
  
  it "should allow --hide-void-return to be set" do
    @yardoc.optparse *%w( --hide-void-return )
    @yardoc.options[:hide_void_return].should be_true
  end
  
  it "should generate all objects with --use-cache" do
    YARD.should_receive(:parse)
    Registry.should_receive(:load)
    Registry.should_receive(:load_all)
    @yardoc.stub!(:generate).and_return(true)
    @yardoc.run *%w( --use-cache )
  end
  
  it "should only generate changed objects with --incremental" do
    YARD.should_receive(:parse)
    Registry.should_receive(:load)
    Registry.should_not_receive(:load_all)
    @yardoc.stub!(:generate).and_return(true)
    @yardoc.should_receive(:generate_with_cache)
    @yardoc.run *%w( --incremental )
    @yardoc.incremental.should == true
    @yardoc.use_cache.should == true
    @yardoc.generate.should == true
  end
end
