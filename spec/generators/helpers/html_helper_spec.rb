require File.dirname(__FILE__) + '/../../spec_helper'

describe YARD::Generators::Helpers::HtmlHelper do
  include YARD::Generators::Helpers::HtmlHelper

  describe '#h' do
    it "should use #h to escape HTML" do
      h('Usage: foo "bar" <baz>').should == "Usage: foo &quot;bar&quot; &lt;baz&gt;"
    end
  end
  
  describe '#fix_typewriter' do
    it "should use #fix_typewriter to convert +text+ to <tt>text</tt>" do
      fix_typewriter("Some +typewriter text+.").should == "Some <tt>typewriter text</tt>."
      fix_typewriter("Not +typewriter text.").should == "Not +typewriter text."
      fix_typewriter("Alternating +type writer+ text +here+.").should == "Alternating <tt>type writer</tt> text <tt>here</tt>."
      fix_typewriter("No ++problem.").should == "No ++problem."
      fix_typewriter("Math + stuff +is ok+").should == "Math + stuff <tt>is ok</tt>"
    end
  end
  
  describe '#htmlify' do
    it "should not use hard breaks for textile markup (RedCloth specific)" do
      htmlify("A\nB", :textile).should_not include("<br")
    end
  end

  describe "#link_object" do
    it "should return the object path if there's no serializer and no title" do
      stub!(:serializer).and_return nil
      link_object(CodeObjects::NamespaceObject.new(nil, :YARD)).should == "YARD"
    end
  
    it "should return the title if there's a title but no serializer" do
      stub!(:serializer).and_return nil
      link_object(CodeObjects::NamespaceObject.new(nil, :YARD), 'title').should == "title"
    end
  end

  describe '#url_for' do
    before { Registry.clear }
  
    it "should return nil if serializer is nil" do
      stub!(:serializer).and_return nil
      stub!(:current_object).and_return Registry.root
      url_for(P("Mod::Class#meth")).should be_nil
    end
  
    it "should return nil if serializer does not implement #serialized_path" do
      stub!(:serializer).and_return Serializers::Base.new
      stub!(:current_object).and_return Registry.root
      url_for(P("Mod::Class#meth")).should be_nil
    end
  
    it "should link to a path/file for a namespace object" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:current_object).and_return Registry.root
    
      yard = CodeObjects::ModuleObject.new(:root, :YARD)
      url_for(yard).should == 'YARD.html'
    end
  
    it "should link to the object's namespace path/file and use the object as the anchor" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:current_object).and_return Registry.root
    
      yard = CodeObjects::ModuleObject.new(:root, :YARD)
      meth = CodeObjects::MethodObject.new(yard, :meth)
      url_for(meth).should == 'YARD.html#meth-instance_method'
    end

    it "should properly urlencode methods with punctuation in links" do
      obj = CodeObjects::MethodObject.new(nil, :/)
      serializer = mock(:serializer)
      serializer.stub!(:serialized_path).and_return("file.html")
      stub!(:serializer).and_return(serializer)
      stub!(:current_object).and_return(obj)
      url_for(obj).should == "#%2F-instance_method"
    end
  end

  describe '#anchor_for' do
    it "should not urlencode data when called directly" do
      obj = CodeObjects::MethodObject.new(nil, :/)
      anchor_for(obj).should == "/-instance_method"
    end
  end

  describe '#resolve_links' do
    def parse_link(link)
      results = {}
      link =~ /<a (.+?)>(.+?)<\/a>/
      params, results[:inner_text] = $1, $2
      params.split(/\s+/).each do |match|
        key, value = *match.split('=')
        results[key.to_sym] = value.gsub(/^["'](.+)["']$/, '\1')
      end
      results
    end

    it "should link static files with file: prefix" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:current_object).and_return Registry.root

      parse_link(resolve_links("{file:TEST.txt#abc}")).should == {
        :inner_text => "TEST.txt",
        :title => "TEST.txt",
        :href => "TEST.txt.html#abc"
      }
      parse_link(resolve_links("{file:TEST.txt title}")).should == {
        :inner_text => "title",
        :title => "title",
        :href => "TEST.txt.html"
      }
    end
  
    it "should create regular links with http:// or https:// prefixes" do
      parse_link(resolve_links("{http://example.com}")).should == {
        :inner_text => "http://example.com",
        :target => "_parent",
        :href => "http://example.com",
        :title => "http://example.com"
      }
      parse_link(resolve_links("{http://example.com title}")).should == {
        :inner_text => "title",
        :target => "_parent",
        :href => "http://example.com",
        :title => "title"
      }
    end
    
    it "should create mailto links with mailto: prefixes" do
      parse_link(resolve_links('{mailto:joanna@example.com}')).should == {
        :inner_text => 'mailto:joanna@example.com',
        :target => '_parent',
        :href => 'mailto:joanna@example.com',
        :title => 'mailto:joanna@example.com'
      }
      parse_link(resolve_links('{mailto:steve@example.com Steve}')).should == {
        :inner_text => 'Steve',
        :target => '_parent',
        :href => 'mailto:steve@example.com',
        :title => 'Steve'
      }
    end
  end
end