require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Tags::Library do
  def tag(docstring)
    Docstring.new(docstring).tags.first
  end

  describe '#see_tag' do
    it "should take a URL" do
      expect(tag("@see http://example.com").name).to eq "http://example.com"
    end

    it "should take an object path" do
      expect(tag("@see String#reverse").name).to eq "String#reverse"
    end

    it "should take a description after the url/object" do
      tag = tag("@see http://example.com An Example Site")
      expect(tag.name).to eq "http://example.com"
      expect(tag.text).to eq "An Example Site"
    end
  end

  describe '.define_tag' do
    it "should allow defining tags with '.' in the name (x.y.z defines method x_y_z)" do
      Tags::Library.define_tag("foo", 'x.y.z')
      Tags::Library.define_tag("foo2", 'x.y.zz', Tags::OverloadTag)
      expect(Tags::Library.instance.method(:x_y_z_tag)).to_not be_nil
      expect(Tags::Library.instance.method(:x_y_zz_tag)).to_not be_nil
      expect(tag('@x.y.z foo bar').text).to eq 'foo bar'
      expect(tag('@x.y.zz foo(bar)').signature).to eq 'foo(bar)'
    end
  end
end
