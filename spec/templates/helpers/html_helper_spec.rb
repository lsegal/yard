require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + "/shared_signature_examples"

describe YARD::Templates::Helpers::HtmlHelper do
  include YARD::Templates::Helpers::HtmlHelper
  include YARD::Templates::Helpers::MethodHelper

  describe '#h' do
    it "should use #h to escape HTML" do
      h('Usage: foo "bar" <baz>').should == "Usage: foo &quot;bar&quot; &lt;baz&gt;"
    end
  end
  
  describe '#fix_typewriter' do
    it "should use #fix_typewriter to convert +text+ to <tt>text</tt>" do
      fix_typewriter("Some +typewriter text+.").should == 
        "Some <tt>typewriter" +
        " text</tt>."
      fix_typewriter("Not +typewriter text.").should == 
        "Not +typewriter text."
      fix_typewriter("Alternating +type writer+ text +here+.").should == 
        "Alternating <tt>type writer" +
        "</tt> text <tt>here</tt>."
      fix_typewriter("No ++problem.").should == 
        "No ++problem."
      fix_typewriter("Math + stuff +is ok+").should == 
        "Math + stuff <tt>is ok</tt>"
    end
    
    it "should not apply to code blocks" do
      fix_typewriter("<code>+hello+</code>").should == "<code>+hello+</code>"
    end
  end
  
  describe '#format_types' do
    it "should include brackets by default" do
      text = ["String"]
      should_receive(:linkify).at_least(1).times.with("String", "String").and_return("String")
      format_types(text).should == format_types(text, true)
      format_types(text).should == "(<tt>String</tt>)"
    end

    it "should avoid brackets if brackets=false" do
      should_receive(:linkify).with("String", "String").and_return("String")
      should_receive(:linkify).with("Symbol", "Symbol").and_return("Symbol")
      format_types(["String", "Symbol"], false).should == "<tt>String</tt>, <tt>Symbol</tt>"
    end
    
    { "String" => [["String"], 
        "<tt><a href=''>String</a></tt>"], 
      "A::B::C" => [["A::B::C"], 
        "<tt><a href=''>A::B::C</a></tt>"],
      "Array<String>" => [["Array", "String"], 
        "<tt><a href=''>Array</a>&lt;<a href=''>String</a>&gt;</tt>"], 
      "Array<String, Symbol>" => [["Array", "String", "Symbol"], 
        "<tt><a href=''>Array</a>&lt;<a href=''>String</a>, <a href=''>Symbol</a>&gt;</tt>"],
      "Array<{String => Array<Symbol>}>" => [["Array", "String", "Array", "Symbol"], 
        "<tt><a href=''>Array</a>&lt;{<a href=''>String</a> =&gt; " +
        "<a href=''>Array</a>&lt;<a href=''>Symbol</a>&gt;}&gt;</tt>"]
    }.each do |text, values|
      it "should link all classes in #{text}" do
        should_receive(:h).with('<').at_least(text.count('<')).times.and_return("&lt;")
        should_receive(:h).with('>').at_least(text.count('>')).times.and_return("&gt;")
        values[0].each {|v| should_receive(:linkify).with(v, v).and_return("<a href=''>#{v}</a>") }
        format_types([text], false).should == values[1]
      end
    end
  end
  
  describe '#htmlify' do
    it "should not use hard breaks for textile markup (RedCloth specific)" do
      htmlify("A\nB", :textile).should_not include("<br")
    end
  end

  describe "#link_object" do
    before do
      stub!(:object).and_return(CodeObjects::NamespaceObject.new(nil, :YARD))
    end
    
    it "should return the object path if there's no serializer and no title" do
      stub!(:serializer).and_return nil
      link_object(CodeObjects::NamespaceObject.new(nil, :YARD)).should == "YARD"
    end
  
    it "should return the title if there's a title but no serializer" do
      stub!(:serializer).and_return nil
      link_object(CodeObjects::NamespaceObject.new(nil, :YARD), 'title').should == "title"
    end

    it "should link objects from overload tag" do
      YARD.parse_string <<-'eof'
        module Foo
          class Bar; def a; end end
          class Baz
            # @overload a
            def a; end
          end
        end
      eof
      obj = Registry.at('Foo::Baz#a').tag(:overload)
      foobar = Registry.at('Foo::Bar')
      foobaz = Registry.at('Foo::Baz')
      serializer = Serializers::FileSystemSerializer.new
      stub!(:serializer).and_return(serializer)
      stub!(:object).and_return(obj)
      link_object("Bar#a").should =~ %r{href="Bar.html#a-instance_method"}
    end
  end

  describe '#url_for' do
    before { Registry.clear }
  
    it "should return nil if serializer is nil" do
      stub!(:serializer).and_return nil
      stub!(:object).and_return Registry.root
      url_for(P("Mod::Class#meth")).should be_nil
    end
  
    it "should return nil if serializer does not implement #serialized_path" do
      stub!(:serializer).and_return Serializers::Base.new
      stub!(:object).and_return Registry.root
      url_for(P("Mod::Class#meth")).should be_nil
    end
  
    it "should link to a path/file for a namespace object" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:object).and_return Registry.root
    
      yard = CodeObjects::ModuleObject.new(:root, :YARD)
      url_for(yard).should == 'YARD.html'
    end
  
    it "should link to the object's namespace path/file and use the object as the anchor" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:object).and_return Registry.root
    
      yard = CodeObjects::ModuleObject.new(:root, :YARD)
      meth = CodeObjects::MethodObject.new(yard, :meth)
      url_for(meth).should == 'YARD.html#meth-instance_method'
    end

    it "should properly urlencode methods with punctuation in links" do
      obj = CodeObjects::MethodObject.new(nil, :/)
      serializer = mock(:serializer)
      serializer.stub!(:serialized_path).and_return("file.html")
      stub!(:serializer).and_return(serializer)
      stub!(:object).and_return(obj)
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
      stub!(:object).and_return Registry.root

      parse_link(resolve_links("{file:TEST.txt#abc}")).should == {
        :inner_text => "TEST.txt",
        :title => "TEST.txt",
        :href => "file.TEST.html#abc"
      }
      parse_link(resolve_links("{file:TEST.txt title}")).should == {
        :inner_text => "title",
        :title => "title",
        :href => "file.TEST.html"
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

  describe '#signature' do
    before do
      @results = {
        :regular => "- (Object) <strong>foo</strong>",
        :default_return => "- (Hello) <strong>foo</strong>",
        :no_default_return => "- <strong>foo</strong>",
        :private_class => "+ (Object) <strong>foo</strong>  <span class=\"extras\">(private)</span>",
        :single => "- (String) <strong>foo</strong>",
        :two_types => "- (String, Symbol) <strong>foo</strong>",
        :two_types_multitag => "- (String, Symbol) <strong>foo</strong>",
        :type_nil => "- (Type<sup>?</sup>) <strong>foo</strong>",
        :type_array => "- (Type<sup>+</sup>) <strong>foo</strong>",
        :multitype => "- (Type, ...) <strong>foo</strong>",
        :void => "- (void) <strong>foo</strong>",
        :hide_void => "- <strong>foo</strong>",
        :block => "- (Object) <strong>foo</strong> {|a, b, c| ... }"
      }
    end
    
    def format_types(types, brackets = false) types.join(", ") end
    def signature(obj) super(obj, false).strip end
    
    it_should_behave_like "signature"
  end
  
  describe '#html_syntax_highlight' do
    before do
      stub!(:options).and_return(:no_highlight => false)
    end
    
    it "should return empty string on nil input" do
      html_syntax_highlight(nil).should == ''
    end
    
    it "should call #html_syntax_highlight_ruby by default" do
      should_receive(:html_syntax_highlight_ruby).with('def x; end')
      html_syntax_highlight('def x; end')
    end
    
    it "should call html_syntax_highlight_NAME if source starts with !!!NAME" do
      should_receive(:respond_to?).with('html_syntax_highlight_NAME').and_return(true)
      should_receive(:html_syntax_highlight_NAME).and_return("foobar")
      html_syntax_highlight(<<-eof
        !!!NAME
        def x; end
      eof
      ).should == "foobar"
    end
    
    it "should not highlight if :no_highlight option is true" do
      stub!(:options).and_return(:no_highlight => true)
      should_not_receive(:html_syntax_highlight_ruby)
      html_syntax_highlight('def x; end').should == 'def x; end'
    end
    
    it "should not highlight if there is no highlight method specified by !!!NAME" do
      should_receive(:respond_to?).with('html_syntax_highlight_NAME').and_return(false)
      should_not_receive(:html_syntax_highlight_NAME)
      html_syntax_highlight("!!!NAME\ndef x; end").should == "def x; end"
    end
  end
  
  describe '#resolve_links' do
    it "should resolve {Name}" do
      should_receive(:link_file).with('TEST', 'TEST', nil).and_return('')
      resolve_links("{file:TEST}")
    end

    it "should resolve ({Name})" do
      should_receive(:link_file).with('TEST', 'TEST', nil).and_return('')
      resolve_links("({file:TEST})")
    end
  end
end
