require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Docstring do
  before { YARD::Registry.clear }
  
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
  
  it "should handle empty docstrings with #summary" do
    o1 = Docstring.new
    o1.summary.should == ""
  end

  it "should return the first sentence with #summary" do
    o = Docstring.new("DOCSTRING. Another sentence")
    o.summary.should == "DOCSTRING."
  end

  it "should return the first paragraph with #summary" do
    o = Docstring.new("DOCSTRING, and other stuff\n\nAnother sentence.")
    o.summary.should == "DOCSTRING, and other stuff."
  end

  it "should return proper summary when docstring is changed" do
    o = Docstring.new "DOCSTRING, and other stuff\n\nAnother sentence."
    o.summary.should == "DOCSTRING, and other stuff."
    o = Docstring.new "DOCSTRING."
    o.summary.should == "DOCSTRING."
  end

  it "should not double the ending period in docstring.summary" do
    o = Docstring.new("Returns a list of tags specified by +name+ or all tags if +name+ is not specified.\n\nTest")
    o.summary.should == "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
  
    doc = Docstring.new(<<-eof)
      
      Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
      
      @param name the tag name to return data for, or nil for all tags
      @return [Array<Tags::Tag>] the list of tags by the specified tag name
    eof
    doc.summary.should == "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
  end
  
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
  
end
