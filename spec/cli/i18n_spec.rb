require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::I18n do
  before do
    @i18n = YARD::CLI::I18n.new
    @i18n.use_document_file = false
    @i18n.use_yardopts_file = false
    output_path = File.expand_path(@i18n.options.serializer.basepath)
    File.stub!(:open!).with(output_path, "wb")
    YARD.stub!(:parse)
  end

  describe 'Defaults' do
    before do
      @i18n = YARD::CLI::I18n.new
      @i18n.stub!(:yardopts).and_return([])
      @i18n.stub!(:support_rdoc_document_file!).and_return([])
      @i18n.parse_arguments
    end

    it "should read .yardopts by default" do
      @i18n.use_yardopts_file.should == true
    end

    it "should use {lib,app}/**/*.rb and ext/**/*.c as default file glob" do
      @i18n.files.should == ['{lib,app}/**/*.rb', 'ext/**/*.c']
    end

    it "should only show public visibility by default" do
      @i18n.visibilities.should == [:public]
    end
  end

  describe 'General options' do
    def self.should_accept(*args, &block)
      @counter ||= 0
      @counter += 1
      counter = @counter
      args.each do |arg|
        define_method("test_options_#{@counter}", &block)
        it("should accept #{arg}") { send("test_options_#{counter}", arg) }
      end
    end

    should_accept('--yardopts') do |arg|
      @i18n = YARD::CLI::I18n.new
      @i18n.use_document_file = false
      @i18n.should_receive(:yardopts).at_least(1).times.and_return([])
      @i18n.parse_arguments(arg)
      @i18n.use_yardopts_file.should == true
      @i18n.parse_arguments('--no-yardopts', arg)
      @i18n.use_yardopts_file.should == true
    end

    should_accept('--yardopts with filename') do |arg|
      @i18n = YARD::CLI::I18n.new
      File.should_receive(:read_binary).with('.yardopts_i18n').and_return('')
      @i18n.use_document_file = false
      @i18n.parse_arguments('--yardopts', '.yardopts_i18n')
      @i18n.use_yardopts_file.should == true
      @i18n.options_file.should == '.yardopts_i18n'
    end

    should_accept('--no-yardopts') do |arg|
      @i18n = YARD::CLI::I18n.new
      @i18n.use_document_file = false
      @i18n.should_not_receive(:yardopts)
      @i18n.parse_arguments(arg)
      @i18n.use_yardopts_file.should == false
      @i18n.parse_arguments('--yardopts', arg)
      @i18n.use_yardopts_file.should == false
    end

    should_accept('--exclude') do |arg|
      YARD.should_receive(:parse).with(['a'], ['nota', 'b'])
      @i18n.run(arg, 'nota', arg, 'b', 'a')
    end
  end

  describe '--no-private option' do
    it "should accept --no-private" do
      obj = mock(:object)
      obj.should_receive(:tag).ordered.with(:private).and_return(true)
      @i18n.parse_arguments *%w( --no-private )
      @i18n.options.verifier.call(obj).should == false
    end

    it "should hide object if namespace is @private with --no-private" do
      ns = mock(:namespace)
      ns.stub!(:type).and_return(:module)
      ns.should_receive(:tag).with(:private).and_return(true)
      obj = mock(:object)
      obj.stub!(:namespace).and_return(ns)
      obj.should_receive(:tag).with(:private).and_return(false)
      @i18n.parse_arguments *%w( --no-private )
      @i18n.options.verifier.call(obj).should == false
    end

    it "should not call #tag on namespace if namespace is proxy with --no-private" do
      ns = mock(:namespace)
      ns.should_receive(:is_a?).with(CodeObjects::Proxy).and_return(true)
      ns.should_not_receive(:tag)
      obj = mock(:object)
      obj.stub!(:type).and_return(:class)
      obj.stub!(:namespace).and_return(ns)
      obj.stub!(:visibility).and_return(:public)
      obj.should_receive(:tag).ordered.with(:private).and_return(false)
      @i18n.parse_arguments *%w( --no-private )
      @i18n.options.verifier.call(obj).should == true
    end

    # @bug gh-197
    it "should not call #tag on namespace if namespace is proxy with --no-private" do
      Registry.clear
      YARD.parse_string "module Qux; class Foo::Bar; end; end"
      foobar = Registry.at('Foo::Bar')
      foobar.namespace.type = :module
      @i18n.parse_arguments *%w( --no-private )
      @i18n.options.verifier.call(foobar).should == true
    end

    it "should not call #tag on proxy object" do # @bug gh-197
      @i18n.parse_arguments *%w( --no-private )
      @i18n.options.verifier.call(P('ProxyClass')).should == true
    end

    it "should hide methods inside a 'private' class/module with --no-private" do
      Registry.clear
      YARD.parse_string <<-eof
        # @private
        class ABC
          def foo; end
        end
      eof
      @i18n.parse_arguments *%w( --no-private )
      @i18n.options.verifier.call(Registry.at('ABC')).should be_false
      @i18n.options.verifier.call(Registry.at('ABC#foo')).should be_false
    end
  end

  describe '.yardopts handling' do
    before do
      @i18n.use_yardopts_file = true
    end

    it "should search for and use yardopts file specified by #options_file" do
      File.should_receive(:read_binary).with("test").and_return("-o \n\nMYPATH\nFILE1 FILE2")
      @i18n.use_document_file = false
      @i18n.options_file = "test"
      File.should_receive(:open!).with(File.expand_path("MYPATH"), "wb")
      @i18n.run
      @i18n.files.should == ["FILE1", "FILE2"]
    end

    it "should use String#shell_split to split .yardopts tokens" do
      optsdata = "foo bar"
      optsdata.should_receive(:shell_split)
      File.should_receive(:read_binary).with("test").and_return(optsdata)
      @i18n.options_file = "test"
      @i18n.run
    end

    it "should allow opts specified in command line to override yardopts file" do
      File.should_receive(:read_binary).with(".yardopts").and_return("-o NOTMYPATH")
      File.should_receive(:open!).with(File.expand_path("MYPATH"), "wb")
      @i18n.run("-o", "MYPATH", "FILE")
      @i18n.files.should == ["FILE"]
    end
  end

  describe 'Query options' do
    before do
      Registry.clear
    end

    it "should setup visibility rules as verifier" do
      methobj = CodeObjects::MethodObject.new(:root, :test) {|o| o.visibility = :private }
      File.should_receive(:read_binary).with("test").and_return("--private")
      @i18n.use_yardopts_file = true
      @i18n.options_file = "test"
      @i18n.run
      @i18n.options.verifier.call(methobj).should be_true
    end

    it "should accept a --query" do
      @i18n.parse_arguments *%w( --query @return )
      @i18n.options.verifier.should be_a(Verifier)
    end

    it "should accept multiple --query arguments" do
      obj = mock(:object)
      obj.should_receive(:tag).ordered.with('return').and_return(true)
      obj.should_receive(:tag).ordered.with('tag').and_return(false)
      @i18n.parse_arguments *%w( --query @return --query @tag )
      @i18n.options.verifier.should be_a(Verifier)
      @i18n.options.verifier.call(obj).should == false
    end
  end

  describe 'Extra file arguments' do
    it "should accept extra files if specified after '-' with source files" do
      Dir.should_receive(:glob).with('README*').and_return([])
      File.should_receive(:file?).with('extra_file1').and_return(true)
      File.should_receive(:file?).with('extra_file2').and_return(true)
      File.should_receive(:read).with('extra_file1').and_return('')
      File.should_receive(:read).with('extra_file2').and_return('')
      @i18n.parse_arguments *%w( file1 file2 - extra_file1 extra_file2 )
      @i18n.files.should == %w( file1 file2 )
      @i18n.options.files.should ==
        [CodeObjects::ExtraFileObject.new('extra_file1', ''),
          CodeObjects::ExtraFileObject.new('extra_file2', '')]
    end

    it "should accept files section only containing extra files" do
      Dir.should_receive(:glob).with('README*').and_return([])
      @i18n.parse_arguments *%w( - LICENSE )
      @i18n.files.should == %w( {lib,app}/**/*.rb ext/**/*.c )
      @i18n.options.files.should == [CodeObjects::ExtraFileObject.new('LICENSE', '')]
    end

    it "should accept globs as extra files" do
      Dir.should_receive(:glob).with('README*').and_return []
      Dir.should_receive(:glob).with('*.txt').and_return ['a.txt', 'b.txt']
      File.should_receive(:read).with('a.txt').and_return('')
      File.should_receive(:read).with('b.txt').and_return('')
      File.should_receive(:file?).with('a.txt').and_return(true)
      File.should_receive(:file?).with('b.txt').and_return(true)
      @i18n.parse_arguments *%w( file1 file2 - *.txt )
      @i18n.files.should == %w( file1 file2 )
      @i18n.options.files.should ==
        [CodeObjects::ExtraFileObject.new('a.txt', ''),
          CodeObjects::ExtraFileObject.new('b.txt', '')]
    end

    it "should warn if extra file is not found" do
      log.should_receive(:warn).with(/Could not find extra file: UNKNOWN/)
      @i18n.parse_arguments *%w( - UNKNOWN )
    end

    it "should warn if readme file is not found" do
      log.should_receive(:warn).with(/Could not find readme file: UNKNOWN/)
      @i18n.parse_arguments *%w( -r UNKNOWN )
    end
  end

  describe 'Source file arguments' do
    it "should accept no params and parse {lib,app}/**/*.rb ext/**/*.c" do
      @i18n.parse_arguments
      @i18n.files.should == %w( {lib,app}/**/*.rb ext/**/*.c )
    end
  end

  describe 'Tags options' do
    def tag_created(switch, factory_method)
      visible_tags = mock(:visible_tags)
      visible_tags.should_receive(:|).ordered.with([:foo])
      visible_tags.should_receive(:-).ordered.with([]).and_return(visible_tags)
      Tags::Library.should_receive(:define_tag).with('Foo', :foo, factory_method)
      Tags::Library.stub!(:visible_tags=)
      Tags::Library.should_receive(:visible_tags).at_least(1).times.and_return(visible_tags)
      @i18n.parse_arguments("--#{switch}-tag", 'foo')
    end

    def tag_hidden(tag)
      visible_tags = mock(:visible_tags)
      visible_tags.should_receive(:|).ordered.with([tag])
      visible_tags.should_receive(:-).ordered.with([tag]).and_return([])
      Tags::Library.should_receive(:define_tag).with(tag.to_s.capitalize, tag, nil)
      Tags::Library.stub!(:visible_tags=)
      Tags::Library.should_receive(:visible_tags).at_least(1).times.and_return(visible_tags)
    end

    it "should accept --tag" do
      Tags::Library.should_receive(:define_tag).with('Title of Foo', :foo, nil)
      @i18n.parse_arguments('--tag', 'foo:Title of Foo')
    end

    it "should accept --tag without title (and default to captialized tag name)" do
      Tags::Library.should_receive(:define_tag).with('Foo', :foo, nil)
      @i18n.parse_arguments('--tag', 'foo')
    end

    it "should only list tag once if declared twice" do
      visible_tags = []
      Tags::Library.stub!(:define_tag)
      Tags::Library.stub!(:visible_tags).and_return([:foo])
      Tags::Library.stub!(:visible_tags=) {|value| visible_tags = value }
      @i18n.parse_arguments('--tag', 'foo', '--tag', 'foo')
      visible_tags.should == [:foo]
    end

    it "should accept --type-tag" do
      tag_created 'type', :with_types
    end

    it "should accept --type-name-tag" do
      tag_created 'type-name', :with_types_and_name
    end

    it "should accept --name-tag" do
      tag_created 'name', :with_name
    end

    it "should accept --title-tag" do
      tag_created 'title', :with_title_and_text
    end

    it "should accept --hide-tag before tag is listed" do
      tag_hidden(:anewfoo)
      @i18n.parse_arguments('--hide-tag', 'anewfoo', '--tag', 'anewfoo')
    end

    it "should accept --hide-tag after tag is listed" do
      tag_hidden(:anewfoo2)
      @i18n.parse_arguments('--tag', 'anewfoo2', '--hide-tag', 'anewfoo2')
    end

    it "should accept --transitive-tag" do
      @i18n.parse_arguments('--transitive-tag', 'foo')
      Tags::Library.transitive_tags.should include(:foo)
    end
  end

  describe '#run' do
    it "should parse_arguments if run() is called" do
      @i18n.should_receive(:parse_arguments)
      @i18n.run
    end

    it "should parse_arguments if run(arg1, arg2, ...) is called" do
      @i18n.should_receive(:parse_arguments)
      @i18n.run('--private', '-p', 'foo')
    end

    it "should not parse_arguments if run(nil) is called" do
      @i18n.should_not_receive(:parse_arguments)
      @i18n.run(nil)
    end
  end
end

describe YARD::CLI::I18n::PotGenerator do
  before do
    @generator = YARD::CLI::I18n::PotGenerator.new("..")
  end

  describe "Generate" do
    it "should generate the default header" do
      @generator.generate.should == <<-'eoh'
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2011-11-20 22:17+0900\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

eoh
    end

    it "should generate messages in location order" do
      @generator.stub!(:header).and_return("HEADER\n\n")
      @generator.messages["tag|see|Parser::SourceParser.parse"] = {
        :locations => [["yard.rb", 14]],
        :comments => ["@see"],
      }
      @generator.messages["Parses a path or set of paths"] = {
        :locations => [["yard.rb", 12], ["yard/parser/source_parser.rb", 83]],
        :comments => ["YARD.parse", "YARD::Parser::SourceParser.parse"],
      }
      @generator.generate.should == <<-'eoh'
HEADER

# YARD.parse
# YARD::Parser::SourceParser.parse
#: ../yard.rb:12
#: ../yard/parser/source_parser.rb:83
msgid "Parses a path or set of paths"
msgstr ""

# @see
#: ../yard.rb:14
msgid "tag|see|Parser::SourceParser.parse"
msgstr ""

eoh
    end
  end

  describe "Escape" do
    def generate_message_pot(message)
      pot = ""
      options = {
        :comments => [],
        :locations => [],
      }
      @generator.send(:generate_message, pot, message, options)
      pot
    end

    it "should escape <\\>" do
      generate_message_pot("hello \\ world").should == <<-'eop'
msgid "hello \\ world"
msgstr ""

eop
    end

    it "should escape <\">" do
      generate_message_pot("hello \" world").should == <<-'eop'
msgid "hello \" world"
msgstr ""

eop
    end

    it "should escape <\\n>" do
      generate_message_pot("hello \n world").should == <<-'eop'
msgid "hello \n"
" world"
msgstr ""

eop
    end
  end

  describe "Object" do
    before do
      Registry.clear
      @yard = YARD::CodeObjects::ModuleObject.new(:root, :YARD)
    end

    it "should extract docstring" do
      object = YARD::CodeObjects::MethodObject.new(@yard, :parse, :module) do |o|
        o.docstring = "An alias to {Parser::SourceParser}'s parsing method"
      end
      @generator.parse_objects([object])
      @generator.messages.should == {
        "An alias to {Parser::SourceParser}'s parsing method" => {
          :locations => [],
          :comments => ["YARD.parse"],
        }
      }
    end

    it "should extract location" do
      object = YARD::CodeObjects::MethodObject.new(@yard, :parse, :module) do |o|
        o.docstring = "An alias to {Parser::SourceParser}'s parsing method"
        o.files = [["yard.rb", 12]]
      end
      @generator.parse_objects([object])
      @generator.messages.should == {
        "An alias to {Parser::SourceParser}'s parsing method" => {
          :locations => [["yard.rb", 13]],
          :comments => ["YARD.parse"],
        }
      }
    end

    it "should extract tag name" do
      object = YARD::CodeObjects::MethodObject.new(@yard, :parse, :module) do |o|
        o.docstring = "@see Parser::SourceParser.parse"
        o.files = [["yard.rb", 12]]
      end
      @generator.parse_objects([object])
      @generator.messages.should == {
        "tag|see|Parser::SourceParser.parse" => {
          :locations => [["yard.rb", 12]],
          :comments => ["@see"],
        },
      }
    end

    it "should extract tag text" do
      object = YARD::CodeObjects::MethodObject.new(@yard, :parse, :module) do |o|
        o.docstring = <<-eod
@example Parse a glob of files
  YARD.parse('lib/**/*.rb')
eod
        o.files = [["yard.rb", 12]]
      end
      @generator.parse_objects([object])
      @generator.messages.should == {
        "tag|example|Parse a glob of files" => {
          :locations => [["yard.rb", 12]],
          :comments => ["@example"],
        },
        "YARD.parse('lib/**/*.rb')" => {
          :locations => [["yard.rb", 12]],
          :comments => ["@example Parse a glob of files"],
        }
      }
    end

    it "should extract tag types" do
      object = YARD::CodeObjects::MethodObject.new(@yard, :parse, :module) do |o|
        o.docstring = <<-eod
@param [String, Array<String>] paths a path, glob, or list of paths to
  parse
eod
        o.files = [["yard.rb", 12]]
      end
      @generator.parse_objects([object])
      @generator.messages.should == {
        "tag|param|paths" => {
          :locations => [["yard.rb", 12]],
          :comments => ["@param [String, Array<String>]"],
        },
        "a path, glob, or list of paths to\nparse" => {
          :locations => [["yard.rb", 12]],
          :comments => ["@param [String, Array<String>] paths"],
        }
      }
    end
  end

  describe "File" do
    it "should extract attribute" do
      path = "GettingStarted.md"
      text = <<-eor
# @title Getting Started Guide

# Getting Started with YARD
eor
      File.stub!(:open).with(path).and_yield(StringIO.new(text))
      File.stub!(:read).with(path).and_return(text)
      file = YARD::CodeObjects::ExtraFileObject.new(path)
      @generator.parse_files([file])
      @generator.messages.should == {
        "Getting Started Guide" => {
          :locations => [[path, 1]],
          :comments => ["title"],
        },
        "# Getting Started with YARD" => {
          :locations => [[path, 3]],
          :comments => [],
        }
      }
    end

    it "should extract paragraphs" do
      path = "README.md"
      paragraph1 = <<-eop.strip
Note that class methods must not be referred to with the "::" namespace
separator. Only modules, classes and constants should use "::".
eop
      paragraph2 = <<-eop.strip
You can also do lookups on any installed gems. Just make sure to build the
.yardoc databases for installed gems with:
eop
      text = <<-eot
#{paragraph1}

#{paragraph2}
eot
      File.stub!(:open).with(path).and_yield(StringIO.new(text))
      File.stub!(:read).with(path).and_return(text)
      file = YARD::CodeObjects::ExtraFileObject.new(path)
      @generator.parse_files([file])
      @generator.messages.should == {
        paragraph1 => {
          :locations => [[path, 1]],
          :comments => [],
        },
        paragraph2 => {
          :locations => [[path, 4]],
          :comments => [],
        }
      }
    end
  end
end

describe YARD::CLI::I18n::Text do
  def extract_messages(input, options={})
    text = YARD::CLI::I18n::Text.new(StringIO.new(input), options)
    messages = []
    text.extract_messages do |*message|
      messages << message
    end
    messages
  end

  describe "Header" do
    it "should extract attribute" do
      text = <<-eot
# @title Getting Started Guide

# Getting Started with YARD
eot
      extract_messages(text, :have_header => true).should ==
        [[:attribute, "title", "Getting Started Guide", 1],
         [:paragraph, "# Getting Started with YARD", 3]]
    end

    it "should ignore markup line" do
      text = <<-eot
#!markdown
# @title Getting Started Guide

# Getting Started with YARD
eot
      extract_messages(text, :have_header => true).should ==
        [[:attribute, "title", "Getting Started Guide", 2],
         [:paragraph, "# Getting Started with YARD", 4]]
    end

    it "should terminate header block by markup line not at the first line" do
      text = <<-eot
# @title Getting Started Guide
#!markdown

# Getting Started with YARD
eot
      extract_messages(text, :have_header => true).should ==
        [[:attribute, "title", "Getting Started Guide", 1],
         [:paragraph, "#!markdown", 2],
         [:paragraph, "# Getting Started with YARD", 4]]
    end
  end

  describe "Body" do
    it "should split to paragraphs" do
      paragraph1 = <<-eop.strip
Note that class methods must not be referred to with the "::" namespace
separator. Only modules, classes and constants should use "::".
eop
      paragraph2 = <<-eop.strip
You can also do lookups on any installed gems. Just make sure to build the
.yardoc databases for installed gems with:
eop
      text = <<-eot
#{paragraph1}

#{paragraph2}
eot
      extract_messages(text).should ==
        [[:paragraph, paragraph1, 1],
         [:paragraph, paragraph2, 4]]
    end
  end
end
