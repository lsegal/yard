require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Docstring do
  before { YARD::Registry.clear }
  
  describe '#initialize' do
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
      doc.tags("param").each do |tag|
        if tag.name == "name"
          tag.text.should == "Hello world how are you?"
        elsif tag.name == "name2"
          tag.text.should == "this is a new line"
        elsif tag.name == "name3"
          tag.text.should == "and this is a new paragraph:\n\nright here."
        end
      end
    end
  
    it "should handle docstrings with empty newlines" do
      Docstring.new("\n\n").should == ""
    end

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
  end
  
  describe '#empty?/#blank?' do
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
  end
end
