require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Docstring do
  before { YARD::Registry.clear }

  describe '#initialize' do
    it "should handle docstrings with empty newlines" do
      expect(Docstring.new("\n\n")).to eq ""
    end
  end

  describe '#+' do
    it "should add another Docstring" do
      d = Docstring.new("FOO") + Docstring.new("BAR")
      expect(d).to eq "FOO\nBAR"
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
      expect(d).to eq "FOOBAR"
    end
  end

  describe '#line' do
    it "should return nil if #line_range is not set" do
      Docstring.new('foo').line.should be_nil
    end

    it "should return line_range.first if #line_range is set" do
      doc = Docstring.new('foo')
      doc.line_range = (1..10)
      expect(doc.line).to eq doc.line_range.first
    end
  end

  describe '#summary' do
    it "should handle empty docstrings" do
      o1 = Docstring.new
      expect(o1.summary).to eq ""
    end

    it "should handle multiple calls" do
      o1 = Docstring.new("Hello. world")
      5.times { expect(o1.summary).to eq "Hello." }
    end

    it "should return the first sentence" do
      o = Docstring.new("DOCSTRING. Another sentence")
    expect(o.summary).to eq "DOCSTRING."
    end

    it "should return the first paragraph" do
      o = Docstring.new("DOCSTRING, and other stuff\n\nAnother sentence.")
    expect(o.summary).to eq "DOCSTRING, and other stuff."
    end

    it "should return proper summary when docstring is changed" do
      o = Docstring.new "DOCSTRING, and other stuff\n\nAnother sentence."
    expect(o.summary).to eq "DOCSTRING, and other stuff."
      o = Docstring.new "DOCSTRING."
    expect(o.summary).to eq "DOCSTRING."
    end

    it "should not double the ending period" do
      o = Docstring.new("Returns a list of tags specified by +name+ or all tags if +name+ is not specified.\n\nTest")
    expect(o.summary).to eq "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."

      doc = Docstring.new(<<-eof)

        Returns a list of tags specified by +name+ or all tags if +name+ is not specified.

        @param name the tag name to return data for, or nil for all tags
        @return [Array<Tags::Tag>] the list of tags by the specified tag name
      eof
    expect(doc.summary).to eq "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
    end

    it "should not attach period if entire summary is include" do
      YARD.parse_string "# docstring\ndef foo; end"
    expect(Docstring.new("{include:#foo}").summary).to eq '{include:#foo}'
      Registry.clear
    end

    it "should handle references embedded in summary" do
    expect(Docstring.new("Aliasing {Test.test}. Done.").summary).to eq "Aliasing {Test.test}."
    end

    it "should only end first sentence when outside parentheses" do
    expect(Docstring.new("Hello (the best.) world. Foo bar.").summary).to eq "Hello (the best.) world."
    expect(Docstring.new("A[b.]c.").summary).to eq "A[b.]c."
    end

    it "should only see '.' as period if whitespace (or eof) follows" do
    expect(Docstring.new("hello 1.5 times.").summary).to eq "hello 1.5 times."
    expect(Docstring.new("hello... me").summary).to eq "hello..."
    expect(Docstring.new("hello.").summary).to eq "hello."
    end
  end

  describe '#ref_tags' do
    it "should parse reference tag into ref_tags" do
      doc = Docstring.new("@return (see Foo#bar)")
    expect(doc.ref_tags.size).to eq 1
    expect(doc.ref_tags.first.owner).to eq P("Foo#bar")
    expect(doc.ref_tags.first.tag_name).to eq "return"
      doc.ref_tags.first.name.should be_nil
    end

    it "should parse named reference tag into ref_tags" do
      doc = Docstring.new("@param blah \n   (see Foo#bar )")
    expect(doc.ref_tags.size).to eq 1
    expect(doc.ref_tags.first.owner).to eq P("Foo#bar")
    expect(doc.ref_tags.first.tag_name).to eq "param"
    expect(doc.ref_tags.first.name).to eq "blah"
    end

    it "should fail to parse named reference tag into ref_tags" do
      doc = Docstring.new("@param blah THIS_BREAKS_REFTAG (see Foo#bar)")
    expect(doc.ref_tags.size).to eq 0
    end

    it "should return all valid reference tags along with #tags" do
      o = CodeObjects::MethodObject.new(:root, 'Foo#bar')
      o.docstring.add_tag Tags::Tag.new('return', 'testing')
      doc = Docstring.new("@return (see Foo#bar)")
      tags = doc.tags
    expect(tags.size).to eq 1
    expect(tags.first.text).to eq 'testing'
      tags.first.should be_kind_of(Tags::RefTag)
    expect(tags.first.owner).to eq o
    end

    it "should return all valid named reference tags along with #tags(name)" do
      o = CodeObjects::MethodObject.new(:root, 'Foo#bar')
      o.docstring.add_tag Tags::Tag.new('param', 'testing', nil, '*args')
      o.docstring.add_tag Tags::Tag.new('param', 'NOTtesting', nil, 'notargs')
      doc = Docstring.new("@param *args (see Foo#bar)")
      tags = doc.tags('param')
    expect(tags.size).to eq 1
    expect(tags.first.text).to eq 'testing'
      tags.first.should be_kind_of(Tags::RefTag)
    expect(tags.first.owner).to eq o
    end

    it "should ignore invalid reference tags" do
      doc = Docstring.new("@param *args (see INVALID::TAG#tag)")
      tags = doc.tags('param')
    expect(tags.size).to eq 0
    end

    it "resolves references to methods in the same class with #methname" do
      klass = CodeObjects::ClassObject.new(:root, "Foo")
      o = CodeObjects::MethodObject.new(klass, "bar")
      ref = CodeObjects::MethodObject.new(klass, "baz")
      o.docstring.add_tag Tags::Tag.new('param', 'testing', nil, 'arg1')
      ref.docstring = "@param (see #bar)"

      tags = ref.docstring.tags("param")
    expect(tags.size).to eq 1
    expect(tags.first.text).to eq "testing"
      tags.first.should be_kind_of(Tags::RefTag)
    expect(tags.first.owner).to eq o
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
    expect(d.blank?(false)).to eq false
    end
  end

  describe '#delete_tags' do
    it "should delete tags by a given tag name" do
      doc = Docstring.new("@param name x\n@param name2 y\n@return foo")
      doc.delete_tags(:param)
    expect(doc.tags.size).to eq 1
    end
  end

  describe '#delete_tag_if' do
    it "should delete tags for a given block" do
      doc = Docstring.new("@param name x\n@param name2 y\n@return foo")
      doc.delete_tag_if {|t| t.name == 'name2' }
    expect(doc.tags.size).to eq 2
    end
  end

  describe '#to_raw' do
    it "should return a clean representation of tags" do
      doc = Docstring.new("Hello world\n@return [String, X] foobar\n@param name<Array> the name\nBYE!")
    expect(doc.to_raw).to eq "Hello world\nBYE!\n@param [Array] name\n  the name\n@return [String, X] foobar"
    end

    it "should handle tags with newlines and indentation" do
      doc = Docstring.new("@example TITLE\n  the \n  example\n  @foo\n@param [X] name\n  the name")
    expect(doc.to_raw).to eq "@example TITLE\n  the \n  example\n  @foo\n@param [X] name\n  the name"
    end

    it "should handle deleted tags" do
      doc = Docstring.new("@example TITLE\n  the \n  example\n  @foo\n@param [X] name\n  the name")
      doc.delete_tags(:param)
    expect(doc.to_raw).to eq "@example TITLE\n  the \n  example\n  @foo"
    end

    it "should handle added tags" do
      doc = Docstring.new("@example TITLE\n  the \n  example\n  @foo")
      doc.add_tag(Tags::Tag.new('foo', 'foo'))
    expect(doc.to_raw).to eq "@example TITLE\n  the \n  example\n  @foo\n@foo foo"
    end

    it "should be equal to .all if not modified" do
      doc = Docstring.new("123\n@param")
    expect(doc.to_raw).to eq doc.all
    end

    # @bug gh-563
    it "should handle full @option tags" do
      doc = Docstring.new("@option foo [String] bar (nil) baz")
    expect(doc.to_raw).to eq "@option foo [String] bar (nil) baz"
    end

    # @bug gh-563
    it "should handle simple @option tags" do
      doc = Docstring.new("@option foo :key bar")
    expect(doc.to_raw).to eq "@option foo :key bar"
    end
  end

  describe '#dup' do
    it "should duplicate docstring text" do
      doc = Docstring.new("foo")
    expect(doc.dup).to eq doc
    expect(doc.dup.all).to eq doc
    end

    it "should duplicate tags to new list" do
      doc = Docstring.new("@param x\n@return y")
      doc2 = doc.dup
      doc2.delete_tags(:param)
    expect(doc.tags.size).to eq 2
    expect(doc2.tags.size).to eq 1
    end

    it "should preserve summary" do
      doc = Docstring.new("foo. bar")
    expect(doc.dup.summary).to eq doc.summary
    end

    it "should preserve hash_flag" do
      doc = Docstring.new
      doc.hash_flag = 'foo'
    expect(doc.dup.hash_flag).to eq doc.hash_flag
    end

    it "should preserve line_range" do
      doc = Docstring.new
      doc.line_range = (1..2)
    expect(doc.dup.line_range).to eq doc.line_range
    end
  end
end
