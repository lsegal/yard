require File.dirname(__FILE__) + "/spec_helper"

describe YARD::DocstringParser do
  after(:all) do
    YARD::Registry.clear
  end

  def parse(content, object = nil, handler = nil)
    @library ||= Tags::Library.instance
    @parser = DocstringParser.new(@library)
    @parser.parse(content, object, handler)
    @parser
  end

  def docstring(content, object = nil, handler = nil)
    parse(content, object, handler).to_docstring
  end

  describe '#parse' do
    it "should parse comments into tags" do
      doc = docstring(<<-eof)
@param name Hello world
  how are you?
@param name2
  this is a new line
@param name3 and this
  is a new paragraph:

  right here.
      eof
      tags = doc.tags(:param)
      expect(tags[0].name).to eq "name"
      expect(tags[0].text).to eq "Hello world\nhow are you?"
      expect(tags[1].name).to eq "name2"
      expect(tags[1].text).to eq "this is a new line"
      expect(tags[2].name).to eq "name3"
      expect(tags[2].text).to eq "and this\nis a new paragraph:\n\nright here."
    end

    it "should end parsing a tag on de-dent" do
      doc = docstring(<<-eof)
@note test
  one two three
rest of docstring
      eof
      expect(doc.tag(:note).text).to eq "test\none two three"
      expect(doc).to eq "rest of docstring"
    end

    it "should parse examples embedded in doc" do
      doc = docstring(<<-eof)
test string here
@example code

  def foo(x, y, z)
  end

  class A; end

more stuff
eof
  expect(doc).to eq "test string here\nmore stuff"
  expect(doc.tag(:example).text).to eq "\ndef foo(x, y, z)\nend\n\nclass A; end"
    end

    it "should remove only original indentation from beginning of line in tags" do
      doc = docstring(<<-eof)
@param name
  some value
  foo bar
   baz
eof
  expect(doc.tag(:param).text).to eq "some value\nfoo bar\n baz"
    end

    it "should allow numbers in tags" do
      Tags::Library.define_tag(nil, :foo1)
      Tags::Library.define_tag(nil, :foo2)
      Tags::Library.define_tag(nil, :foo3)
      doc = docstring(<<-eof)
@foo1 bar1
@foo2 bar2
@foo3 bar3
eof
  expect(doc.tag(:foo1).text).to eq "bar1"
  expect(doc.tag(:foo2).text).to eq "bar2"
    end

    it "should end tag on newline if next line is not indented" do
      doc = docstring(<<-eof)
@author bar1
@api bar2
Hello world
eof
  expect(doc.tag(:author).text).to eq "bar1"
  expect(doc.tag(:api).text).to eq "bar2"
    end

    it "should warn about unknown tag" do
      log.should_receive(:warn).with(/Unknown tag @hello$/)
      docstring("@hello world")
    end

    it "should not add trailing whitespace to freeform tags" do
      doc = docstring("@api private   \t   ")
  expect(doc.tag(:api).text).to eq "private"
    end
  end

  describe '#parse with custom tag library' do
    class TestLibrary < Tags::Library; end

    before { @library = TestLibrary.new }

    it "should accept valid tags" do
      valid = %w( testing valid is_a is_A __ )
      valid.each do |tag|
        TestLibrary.define_tag("Tag", tag)
        doc = docstring('@' + tag + ' foo bar')
        expect(doc.tag(tag).text).to eq 'foo bar'
      end
    end

    it "should not parse invalid tag names" do
      invalid = %w( @ @return@ @param, @x-y @.x.y.z )
      invalid.each do |tag|
        expect(docstring(tag + ' foo bar')).to eq tag + ' foo bar'
      end
    end

    it "should allow namespaced tags in the form @x.y.z" do
      TestLibrary.define_tag("Tag", 'x.y.z')
      doc = docstring("@x.y.z foo bar")
      expect(doc.tag('x.y.z').text).to eq 'foo bar'
    end

    it "should ignore new directives without @! prefix syntax" do
      TestLibrary.define_directive('dir1', Tags::ScopeDirective)
      log.should_receive(:warn).with(/@dir1/)
      docstring("@dir1")
    end

    %w(attribute endgroup group macro method scope visibility).each do |tag|
      it "should handle non prefixed @#{tag} syntax as directive, not tag" do
        TestLibrary.define_directive(tag, Tags::ScopeDirective)
        parse("@#{tag}")
        @parser.directives.first.should be_a(Tags::ScopeDirective)
      end
    end

    it "should handle directives with @! prefix syntax" do
      TestLibrary.define_directive('dir1', Tags::ScopeDirective)
      docstring("@!dir1 class")
      expect(@parser.state.scope).to eq :class
    end
  end

  describe '#text' do
    it "should only return text data" do
      parse("Foo\n@param foo x y z\nBar")
      expect(@parser.text).to eq "Foo\nBar"
    end
  end

  describe '#raw_text' do
    it "should return the entire original data" do
      data = "Foo\n@param foo x y z\nBar"
      parse(data)
      expect(@parser.raw_text).to eq data
    end
  end

  describe '#tags' do
    it "should return the parsed tags" do
      data = "Foo\n@param foo x y z\nBar"
      parse(data)
      expect(@parser.tags.size).to eq 1
      expect(@parser.tags.first.tag_name).to eq 'param'
    end
  end

  describe '#directives' do
    it "should group all processed directives" do
      data = "Foo\n@!scope class\n@!visibility private\nBar"
      parse(data)
      dirs = @parser.directives
      #dirs.size == 2 # PCO - does nothing
      dirs[0].should be_a(Tags::ScopeDirective)
      expect(dirs[0].tag.text).to eq 'class'
      dirs[1].should be_a(Tags::VisibilityDirective)
      expect(dirs[1].tag.text).to eq 'private'
    end
  end

  describe '#state' do
    it "should handle modified state" do
      parse("@!scope class")
      expect(@parser.state.scope).to eq :class
    end
  end

  describe 'after_parse' do
    it "should allow specifying of callbacks" do
      parser = DocstringParser.new
      the_yielded_obj = nil
      DocstringParser.after_parse {|obj| the_yielded_obj = obj }
      parser.parse("Some text")
      expect(the_yielded_obj).to eq parser
    end

    it "should warn about invalid named parameters" do
      log.should_receive(:warn).with(/@param tag has unknown parameter name: notaparam/)
      YARD.parse_string <<-eof
        # @param notaparam foo
        def foo(a) end
      eof
    end

    it "should warn about duplicate named parameters" do
      log.should_receive(:warn).with(/@param tag has duplicate parameter name: a/)
      YARD.parse_string <<-eof
        # @param a foo
        # @param a foo
        def foo(a) end
      eof
    end
  end
end
