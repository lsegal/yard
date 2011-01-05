require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Docstring do
  before { YARD::Registry.clear }
  
  describe '#initialize' do
    it "should handle docstrings with empty newlines" do
      Docstring.new("\n\n").should == ""
    end
  end
  
  describe '#+' do
    it "should add another Docstring" do
      d = Docstring.new("FOO") + Docstring.new("BAR")
      d.should == "FOO\nBAR"
    end
    
    it "should copy over tags" do
      d1 = Docstring.new("FOO\n@api private\n")
      d2 = Docstring.new("BAR\n@param foo descr")
      d = (d1 + d2)
      d.should have_tag(:api)
      d.should have_tag(:param)
    end
      
    it "should add a String" do
      d = Docstring.new("FOO") + "BAR"
      d.should == "FOOBAR"
    end
  end
  
  describe '#summary' do
    it "should handle empty docstrings" do
      o1 = Docstring.new
      o1.summary.should == ""
    end
  
    it "should handle multiple calls" do
      o1 = Docstring.new("Hello. world")
      5.times { o1.summary.should == "Hello." }
    end

    it "should return the first sentence" do
      o = Docstring.new("DOCSTRING. Another sentence")
      o.summary.should == "DOCSTRING."
    end

    it "should return the first paragraph" do
      o = Docstring.new("DOCSTRING, and other stuff\n\nAnother sentence.")
      o.summary.should == "DOCSTRING, and other stuff."
    end

    it "should return proper summary when docstring is changed" do
      o = Docstring.new "DOCSTRING, and other stuff\n\nAnother sentence."
      o.summary.should == "DOCSTRING, and other stuff."
      o = Docstring.new "DOCSTRING."
      o.summary.should == "DOCSTRING."
    end

    it "should not double the ending period" do
      o = Docstring.new("Returns a list of tags specified by +name+ or all tags if +name+ is not specified.\n\nTest")
      o.summary.should == "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
  
      doc = Docstring.new(<<-eof)
      
        Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
      
        @param name the tag name to return data for, or nil for all tags
        @return [Array<Tags::Tag>] the list of tags by the specified tag name
      eof
      doc.summary.should == "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
    end
    
    it "should handle references embedded in summary" do
      Docstring.new("Aliasing {Test.test}. Done.").summary.should == "Aliasing {Test.test}."
    end
    
    it "should only end first sentence when outside parentheses" do
      Docstring.new("Hello (the best.) world. Foo bar.").summary.should == "Hello (the best.) world."
      Docstring.new("A[b.]c.").summary.should == "A[b.]c."
    end
    
    it "should only see '.' as period if whitespace (or eof) follows" do
      Docstring.new("hello 1.5 times.").summary.should == "hello 1.5 times."
      Docstring.new("hello... me").summary.should == "hello..."
      Docstring.new("hello.").summary.should == "hello."
    end
  end

  describe '#ref_tags' do
    it "should parse reference tag into ref_tags" do
      doc = Docstring.new("@return (see Foo#bar)")
      doc.ref_tags.size.should == 1
      doc.ref_tags.first.owner.should == P("Foo#bar")
      doc.ref_tags.first.tag_name.should == "return"
      doc.ref_tags.first.name.should be_nil
    end

    it "should parse named reference tag into ref_tags" do
      doc = Docstring.new("@param blah \n   (see Foo#bar )")
      doc.ref_tags.size.should == 1
      doc.ref_tags.first.owner.should == P("Foo#bar")
      doc.ref_tags.first.tag_name.should == "param"
      doc.ref_tags.first.name.should == "blah"
    end
  
    it "should fail to parse named reference tag into ref_tags" do
      doc = Docstring.new("@param blah THIS_BREAKS_REFTAG (see Foo#bar)")
      doc.ref_tags.size.should == 0
    end
  
    it "should return all valid reference tags along with #tags" do
      o = CodeObjects::MethodObject.new(:root, 'Foo#bar')
      o.docstring.add_tag Tags::Tag.new('return', 'testing')
      doc = Docstring.new("@return (see Foo#bar)")
      tags = doc.tags
      tags.size.should == 1
      tags.first.text.should == 'testing'
      tags.first.should be_kind_of(Tags::RefTag)
      tags.first.owner.should == o
    end
  
    it "should return all valid named reference tags along with #tags(name)" do
      o = CodeObjects::MethodObject.new(:root, 'Foo#bar')
      o.docstring.add_tag Tags::Tag.new('param', 'testing', nil, '*args')
      o.docstring.add_tag Tags::Tag.new('param', 'NOTtesting', nil, 'notargs')
      doc = Docstring.new("@param *args (see Foo#bar)")
      tags = doc.tags('param')
      tags.size.should == 1
      tags.first.text.should == 'testing'
      tags.first.should be_kind_of(Tags::RefTag)
      tags.first.owner.should == o
    end

    it "should ignore invalid reference tags" do
      doc = Docstring.new("@param *args (see INVALID::TAG#tag)")
      tags = doc.tags('param')
      tags.size.should == 0
    end
    
    it "resolves references to methods in the same class with #methname" do
      klass = CodeObjects::ClassObject.new(:root, "Foo")
      o = CodeObjects::MethodObject.new(klass, "bar")
      ref = CodeObjects::MethodObject.new(klass, "baz")
      o.docstring.add_tag Tags::Tag.new('param', 'testing', nil, 'arg1')
      ref.docstring = "@param (see #bar)"
      
      tags = ref.docstring.tags("param")
      tags.size.should == 1
      tags.first.text.should == "testing"
      tags.first.should be_kind_of(Tags::RefTag)
      tags.first.owner.should == o
    end
  end
  
  describe '#empty?/#blank?' do
    before(:all) do
      Tags::Library.define_tag "Invisible", :invisible_tag
    end

    it "should be blank and empty if it has no content and no tags" do
      Docstring.new.should be_blank
      Docstring.new.should be_empty
    end

    it "shouldn't be empty or blank if it has content" do
      d = Docstring.new("foo bar")
      d.should_not be_empty
      d.should_not be_blank
    end

    it "should be empty but not blank if it has tags" do
      d = Docstring.new("@param foo")
      d.should be_empty
      d.should_not be_blank
    end

    it "should be empty but not blank if it has ref tags" do
      o = CodeObjects::MethodObject.new(:root, 'Foo#bar')
      o.docstring.add_tag Tags::Tag.new('return', 'testing')
      d = Docstring.new("@return (see Foo#bar)")
      d.should be_empty
      d.should_not be_blank
    end
    
    it "should be blank if it has no visible tags" do
      d = Docstring.new("@invisible_tag value")
      d.should be_blank
    end
    
    it "should not be blank if it has invisible tags and only_visible_tags = false" do
      d = Docstring.new("@invisible_tag value")
      d.add_tag Tags::Tag.new('invisible_tag', nil, nil)
      d.blank?(false).should == false
    end
  end
  
  describe '#add_tag' do
    it "should only parse tags with charset [A-Za-z_]" do
      doc = Docstring.new
      valid = %w( @testing @valid @is_a @is_A @__ )
      invalid = %w( @ @return@ @param, @x.y @x-y )

      log.enter_level(Logger::FATAL) do
        {valid => 1, invalid => 0}.each do |tags, size|
          tags.each do |tag|
            class << doc
              def create_tag(tag_name, *args)
                add_tag Tags::Tag.new(tag_name, *args)
              end
            end
            doc.all = tag
            doc.tags(tag[1..-1]).size.should == size
          end
        end
      end
    end
  end
  
  describe '#parse_comments' do
    it "should parse comments into tags" do
      doc = Docstring.new(<<-eof)
@param name Hello world
  how are you?
@param name2 
  this is a new line
@param name3 and this
  is a new paragraph:

  right here.
      eof
      tags = doc.tags(:param)
      tags[0].name.should == "name"
      tags[0].text.should == "Hello world\nhow are you?"
      tags[1].name.should == "name2"
      tags[1].text.should == "this is a new line"
      tags[2].name.should == "name3"
      tags[2].text.should == "and this\nis a new paragraph:\n\nright here."
    end

    it "should end parsing a tag on de-dent" do
      doc = Docstring.new(<<-eof)
@note test
  one two three
rest of docstring
      eof
      doc.tag(:note).text.should == "test\none two three"
      doc.should == "rest of docstring"
    end
    
    it "should parse examples embedded in doc" do
      doc = Docstring.new(<<-eof)
test string here
@example code
  
  def foo(x, y, z)
  end
  
  class A; end

more stuff
eof
      doc.should == "test string here\nmore stuff"
      doc.tag(:example).text.should == "\ndef foo(x, y, z)\nend\n\nclass A; end"
    end
    
    it "should remove only original indentation from beginning of line in tags" do
      doc = Docstring.new(<<-eof)
@param name
  some value
  foo bar
   baz
eof
      doc.tag(:param).text.should == "some value\nfoo bar\n baz"
    end

    it "should allow numbers in tags" do
      Tags::Library.define_tag(nil, :foo1)
      Tags::Library.define_tag(nil, :foo2)
      Tags::Library.define_tag(nil, :foo3)
      doc = Docstring.new(<<-eof)
@foo1 bar1
@foo2 bar2
@foo3 bar3
eof
      doc.tag(:foo1).text.should == "bar1"
      doc.tag(:foo2).text.should == "bar2"
    end
    
    it "should end tag on newline if next line is not indented" do
      doc = Docstring.new(<<-eof)
@author bar1
@api bar2
Hello world
eof
      doc.tag(:author).text.should == "bar1"
      doc.tag(:api).text.should == "bar2"
    end
    
    it "should warn about unknown tag" do
      log.should_receive(:warn).with(/Unknown tag @hello$/)
      Docstring.new("@hello world")
    end
    
    it "should not add trailing whitespace to freeform tags" do
      doc = Docstring.new("@api private   \t   ")
      doc.tag(:api).text.should == "private"
    end
  end
end
