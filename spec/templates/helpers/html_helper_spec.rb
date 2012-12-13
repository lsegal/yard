require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + "/shared_signature_examples"
require 'ostruct'

describe YARD::Templates::Helpers::HtmlHelper do
  include YARD::Templates::Helpers::BaseHelper
  include YARD::Templates::Helpers::HtmlHelper
  include YARD::Templates::Helpers::MethodHelper

  def options
    Templates::TemplateOptions.new.tap do |o|
      o.reset_defaults
      o.default_return = nil
    end
  end

  describe '#h' do
    it "should use #h to escape HTML" do
      expect(h('Usage: foo "bar" <baz>')).to eq "Usage: foo &quot;bar&quot; &lt;baz&gt;"
    end
  end

  describe '#charset' do
    it "should return foo if LANG=foo" do
      ENV.should_receive(:[]).with('LANG').and_return('shift_jis') if YARD.ruby18?
      Encoding.default_external.should_receive(:name).and_return('shift_jis') if defined?(Encoding)
      expect(charset).to eq 'shift_jis'
    end

    ['US-ASCII', 'ASCII-7BIT', 'ASCII-8BIT'].each do |type|
      it "should convert #{type} to iso-8859-1" do
        ENV.should_receive(:[]).with('LANG').and_return(type) if YARD.ruby18?
        Encoding.default_external.should_receive(:name).and_return(type) if defined?(Encoding)
        expect(charset).to eq 'iso-8859-1'
      end
    end

    it "should support utf8 as an encoding value for utf-8" do
      type = 'utf8'
      ENV.should_receive(:[]).with('LANG').and_return(type) if YARD.ruby18?
      Encoding.default_external.should_receive(:name).and_return(type) if defined?(Encoding)
      expect(charset).to eq 'utf-8'
    end

    it "should take file encoding if there is a file" do
      @file = OpenStruct.new(:contents => 'foo'.force_encoding('sjis'))
      # not the correct charset name, but good enough
      ['Shift_JIS', 'Windows-31J'].should include(charset)
    end if YARD.ruby19?

    it "should take file encoding if there is a file" do
      ENV.stub!(:[]).with('LANG').and_return('utf-8') if YARD.ruby18?
      @file = OpenStruct.new(:contents => 'foo')
      expect(charset).to eq 'utf-8'
    end if YARD.ruby18?

    if YARD.ruby18?
      it "should return utf-8 if no LANG env is set" do
        ENV.should_receive(:[]).with('LANG').and_return(nil)
        expect(charset).to eq 'utf-8'
      end

      it "should only return charset part of lang" do
        ENV.should_receive(:[]).with('LANG').and_return('en_US.UTF-8')
        expect(charset).to eq 'utf-8'
      end
    end
  end

  describe '#format_types' do
    it "should include brackets by default" do
      text = ["String"]
      should_receive(:linkify).at_least(1).times.with("String", "String").and_return("String")
      expect(format_types(text)).to eq format_types(text, true)
      expect(format_types(text)).to eq "(<tt>String</tt>)"
    end

    it "should avoid brackets if brackets=false" do
      should_receive(:linkify).with("String", "String").and_return("String")
      should_receive(:linkify).with("Symbol", "Symbol").and_return("Symbol")
      expect(format_types(["String", "Symbol"], false)).to eq "<tt>String</tt>, <tt>Symbol</tt>"
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
        expect(format_types([text], false)).to eq values[1]
      end
    end
  end

  describe '#htmlify' do
    it "should not use hard breaks for textile markup (RedCloth specific)" do
      begin; require 'redcloth'; rescue LoadError; pending 'test requires redcloth gem' end
      htmlify("A\nB", :textile).should_not include("<br")
    end

    it "should use hard breaks for textile_strict markup (RedCloth specific)" do
      begin; require 'redcloth'; rescue LoadError; pending 'test requires redcloth gem' end
      htmlify("A\nB", :textile_strict).should include("<br")
    end

    it "should handle various encodings" do
      stub!(:object).and_return(Registry.root)
      Encoding.default_internal = 'utf-8' if defined?(Encoding)
      htmlify("\xB0\xB1", :text)
      # TODO: add more encoding tests
    end

    it "should return pre-formatted text with :pre markup" do
      expect(htmlify("fo\no\n\nbar<>", :pre)).to eq "<pre>fo\no\n\nbar&lt;&gt;</pre>"
    end

    it "should return regular text with :text markup" do
      expect(htmlify("fo\no\n\nbar<>", :text)).to eq "fo<br/>o<br/><br/>bar&lt;&gt;"
    end

    it "should return unmodified text with :none markup" do
      expect(htmlify("fo\no\n\nbar<>", :none)).to eq "fo\no\n\nbar&lt;&gt;"
    end

    it "should highlight ruby if markup is :ruby" do
      htmlify("class Foo; end", :ruby).should =~ /\A<pre class="code ruby"><span/
    end

    it "should include file and htmlify it" do
      load_markup_provider(:rdoc)
      File.should_receive(:file?).with('foo.rdoc').and_return(true)
      File.should_receive(:read).with('foo.rdoc').and_return('HI')
      expect(htmlify("{include:file:foo.rdoc}", :rdoc).gsub(/\s+/, '')).to eq "<p><p>HI</p></p>"
    end

    it "should autolink URLs (markdown specific)" do
      log.enter_level(Logger::FATAL) do
        unless markup_class(:markdown).to_s == "RedcarpetCompat"
          pending 'This test depends on a markdown engine that supports autolinking'
        end
      end
      expect(htmlify('http://example.com', :markdown).chomp.gsub('&#47;', '/')).to eq '<p><a href="http://example.com">http://example.com</a></p>'
    end

    it "should not autolink URLs inside of {} (markdown specific)" do
      log.enter_level(Logger::FATAL) do
        pending 'This test depends on markdown' unless markup_class(:markdown)
      end
      htmlify('{http://example.com Title}', :markdown).chomp.should =~
        %r{<p><a href="http://example.com".*>Title</a></p>}
      htmlify('{http://example.com}', :markdown).chomp.should =~
        %r{<p><a href="http://example.com".*>http://example.com</a></p>}
    end
  end

  describe "#link_object" do
    before do
      stub!(:object).and_return(CodeObjects::NamespaceObject.new(nil, :YARD))
    end

    it "should return the object path if there's no serializer and no title" do
      stub!(:serializer).and_return nil
      expect(link_object(CodeObjects::NamespaceObject.new(nil, :YARD))).to eq "YARD"
    end

    it "should return the title if there's a title but no serializer" do
      stub!(:serializer).and_return nil
      expect(link_object(CodeObjects::NamespaceObject.new(nil, :YARD), 'title')).to eq "title"
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

    it "should use relative path in title" do
      CodeObjects::ModuleObject.new(:root, :YARD)
      CodeObjects::ClassObject.new(P('YARD'), :Bar)
      stub!(:object).and_return(CodeObjects::ModuleObject.new(P('YARD'), :Foo))
      serializer = Serializers::FileSystemSerializer.new
      stub!(:serializer).and_return(serializer)
      link_object("Bar").should =~ %r{>Bar</a>}
    end

    it "should use relative path to parent class in title" do
      root = CodeObjects::ModuleObject.new(:root, :YARD)
      obj = CodeObjects::ModuleObject.new(root, :SubModule)
      stub!(:object).and_return(obj)
      serializer = Serializers::FileSystemSerializer.new
      stub!(:serializer).and_return(serializer)
      link_object("YARD").should =~ %r{>YARD</a>}
    end

    it "should use Klass.foo when linking to class method in current namespace" do
      root = CodeObjects::ModuleObject.new(:root, :Klass)
      obj = CodeObjects::MethodObject.new(root, :foo, :class)
      stub!(:object).and_return(root)
      serializer = Serializers::FileSystemSerializer.new
      stub!(:serializer).and_return(serializer)
      link_object("foo").should =~ %r{>Klass.foo</a>}
    end

    it "should escape method name in title" do
      YARD.parse_string <<-'eof'
        class Array
          def &(other)
          end
        end
      eof
      obj = Registry.at('Array#&')
      serializer = Serializers::FileSystemSerializer.new
      stub!(:serializer).and_return(serializer)
      stub!(:object).and_return(obj)
      link_object("Array#&").should =~ %r{title="Array#&amp; \(method\)"}
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
        expect(url_for(yard)).to eq 'YARD.html'
    end

    it "should link to the object's namespace path/file and use the object as the anchor" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:object).and_return Registry.root

      yard = CodeObjects::ModuleObject.new(:root, :YARD)
      meth = CodeObjects::MethodObject.new(yard, :meth)
        expect(url_for(meth)).to eq 'YARD.html#meth-instance_method'
    end

    it "should properly urlencode methods with punctuation in links" do
      obj = CodeObjects::MethodObject.new(nil, :/)
      serializer = mock(:serializer)
      serializer.stub!(:serialized_path).and_return("file.html")
      stub!(:serializer).and_return(serializer)
      stub!(:object).and_return(obj)
        expect(url_for(obj)).to eq "#%2F-instance_method"
    end
  end

  describe '#anchor_for' do
    it "should not urlencode data when called directly" do
      obj = CodeObjects::MethodObject.new(nil, :/)
        expect(anchor_for(obj)).to eq "/-instance_method"
    end
  end

  describe '#resolve_links' do
    def parse_link(link)
      results = {}
      link =~ /<a (.+?)>(.+?)<\/a>/m
      params, results[:inner_text] = $1, $2
      params.scan(/\s*(\S+?)=['"](.+?)['"]\s*/).each do |key, value|
        results[key.to_sym] = value.gsub(/^["'](.+)["']$/, '\1')
      end
      results
    end

    it "should escape {} syntax with backslash (\\{foo bar})" do
      input  = '\{foo bar} \{XYZ} \{file:FOO} $\{N-M}'
      output = '{foo bar} {XYZ} {file:FOO} ${N-M}'
      expect(resolve_links(input)).to eq output
    end

    it "should escape {} syntax with ! (!{foo bar})" do
      input  = '!{foo bar} !{XYZ} !{file:FOO} $!{N-M}'
      output = '{foo bar} {XYZ} {file:FOO} ${N-M}'
      expect(resolve_links(input)).to eq output
    end

    it "should link static files with file: prefix" do
      stub!(:serializer).and_return Serializers::FileSystemSerializer.new
      stub!(:object).and_return Registry.root

      expect(parse_link(resolve_links("{file:TEST.txt#abc}"))).to eq({
        :inner_text => "TEST",
        :title => "TEST",
        :href => "file.TEST.html#abc"
      })
      expect(parse_link(resolve_links("{file:TEST.txt title}"))).to eq({
        :inner_text => "title",
        :title => "title",
        :href => "file.TEST.html"
      })
    end

    it "should create regular links with http:// or https:// prefixes" do
      expect(parse_link(resolve_links("{http://example.com}"))).to eq({
        :inner_text => "http://example.com",
        :target => "_parent",
        :href => "http://example.com",
        :title => "http://example.com"
      })
      expect(parse_link(resolve_links("{http://example.com title}"))).to eq({
        :inner_text => "title",
        :target => "_parent",
        :href => "http://example.com",
        :title => "title"
      })
    end

    it "should create mailto links with mailto: prefixes" do
      expect(parse_link(resolve_links('{mailto:joanna@example.com}'))).to eq({
        :inner_text => 'mailto:joanna@example.com',
        :target => '_parent',
        :href => 'mailto:joanna@example.com',
        :title => 'mailto:joanna@example.com'
      })
      expect(parse_link(resolve_links('{mailto:steve@example.com Steve}'))).to eq({
        :inner_text => 'Steve',
        :target => '_parent',
        :href => 'mailto:steve@example.com',
        :title => 'Steve'
      })
    end

    it "should ignore {links} that begin with |...|" do
      expect(resolve_links("{|x|x == 1}")).to eq "{|x|x == 1}"
    end

    it "should gracefully ignore {} in links" do
      should_receive(:linkify).with('Foo', 'Foo').and_return('FOO')
      expect(resolve_links("{} {} {Foo Foo}")).to eq '{} {} FOO'
    end

    %w(tt code pre).each do |tag|
      it "should ignore links in <#{tag}>" do
        text = "<#{tag}>{Foo}</#{tag}>"
        expect(resolve_links(text)).to eq text
      end
    end

    it "should resolve {Name}" do
      should_receive(:link_file).with('TEST', nil, nil).and_return('')
      resolve_links("{file:TEST}")
    end

    it "should resolve ({Name})" do
      should_receive(:link_file).with('TEST', nil, nil).and_return('')
      resolve_links("({file:TEST})")
    end

    it "should resolve link with newline in title-part" do
      expect(parse_link(resolve_links("{http://example.com foo\nbar}"))).to eq({
        :inner_text => "foo bar",
        :target => "_parent",
        :href => "http://example.com",
        :title => "foo bar"
      })
    end

    it "should resolve links to methods whose names have been escaped" do
      should_receive(:linkify).with('Object#<<', nil).and_return('')
      resolve_links("{Object#&lt;&lt;}")
    end

    it "should warn about missing reference at right file location for object" do
      YARD.parse_string <<-eof
        # Comments here
        # And a reference to {InvalidObject}
        class MyObject; end
      eof
      logger = mock(:log)
      logger.should_receive(:warn).ordered.with("In file `(stdin)':2: Cannot resolve link to InvalidObject from text:")
      logger.should_receive(:warn).ordered.with("...{InvalidObject}")
      stub!(:log).and_return(logger)
      stub!(:object).and_return(Registry.at('MyObject'))
      resolve_links(object.docstring)
    end

    it "should show ellipsis on either side if there is more on the line in a reference warning" do
      YARD.parse_string <<-eof
        # {InvalidObject1} beginning of line
        # end of line {InvalidObject2}
        # Middle of {InvalidObject3} line
        # {InvalidObject4}
        class MyObject; end
      eof
      logger = mock(:log)
      logger.should_receive(:warn).ordered.with("In file `(stdin)':1: Cannot resolve link to InvalidObject1 from text:")
      logger.should_receive(:warn).ordered.with("{InvalidObject1}...")
      logger.should_receive(:warn).ordered.with("In file `(stdin)':2: Cannot resolve link to InvalidObject2 from text:")
      logger.should_receive(:warn).ordered.with("...{InvalidObject2}")
      logger.should_receive(:warn).ordered.with("In file `(stdin)':3: Cannot resolve link to InvalidObject3 from text:")
      logger.should_receive(:warn).ordered.with("...{InvalidObject3}...")
      logger.should_receive(:warn).ordered.with("In file `(stdin)':4: Cannot resolve link to InvalidObject4 from text:")
      logger.should_receive(:warn).ordered.with("{InvalidObject4}")
      stub!(:log).and_return(logger)
      stub!(:object).and_return(Registry.at('MyObject'))
      resolve_links(object.docstring)
    end

    it "should warn about missing reference for file template (no object)" do
      @file = CodeObjects::ExtraFileObject.new('myfile.txt', '')
      logger = mock(:log)
      logger.should_receive(:warn).ordered.with("In file `myfile.txt':3: Cannot resolve link to InvalidObject from text:")
      logger.should_receive(:warn).ordered.with("...{InvalidObject Some Title}")
      stub!(:log).and_return(logger)
      stub!(:object).and_return(Registry.root)
      resolve_links(<<-eof)
        Hello world
        This is a line
        And {InvalidObject Some Title}
        And more.
      eof
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
        :block => "- (Object) <strong>foo</strong> {|a, b, c| ... }",
        :empty_overload => '- (String) <strong>foobar</strong>'
      }
    end

    def format_types(types, brackets = false) types.join(", ") end
    def signature(obj, link = false) super(obj, link).strip end

    it_should_behave_like "signature"

    it "should link to regular method if overload name does not have the same method name" do
      YARD.parse_string <<-eof
        class Foo
          # @overload bar(a, b, c)
          def foo; end
        end
      eof
      serializer = mock(:serializer)
      serializer.stub!(:serialized_path).with(Registry.at('Foo')).and_return('')
      stub!(:serializer).and_return(serializer)
      stub!(:object).and_return(Registry.at('Foo'))
        expect(signature(Registry.at('Foo#foo').tag(:overload), true)).to eq "<a href=\"#foo-instance_method\" title=\"#bar (instance method)\">- <strong>bar</strong>(a, b, c) </a>"
    end
  end

  describe '#html_syntax_highlight' do
    subject do
      obj = OpenStruct.new
      obj.options = options
      obj.object = Registry.root
      obj.extend(Templates::Helpers::HtmlHelper)
      obj
    end

    it "should return empty string on nil input" do
        expect(subject.html_syntax_highlight(nil)).to eq ''
    end

    it "should call #html_syntax_highlight_ruby by default" do
      Registry.root.source_type = nil
      subject.should_receive(:html_syntax_highlight_ruby).with('def x; end')
      subject.html_syntax_highlight('def x; end')
    end

    it "should call #html_syntax_highlight_NAME if there's an object with a #source_type" do
      subject.object = OpenStruct.new(:source_type => :NAME)
      subject.should_receive(:respond_to?).with('html_markup_html').and_return(true)
      subject.should_receive(:respond_to?).with('html_syntax_highlight_NAME').and_return(true)
      subject.should_receive(:html_syntax_highlight_NAME).and_return("foobar")
        expect(subject.htmlify('<pre><code>def x; end</code></pre>', :html)).to eq '<pre class="code NAME"><code>foobar</code></pre>'
    end

    it "should add !!!LANG to className in outputted pre tag" do
      subject.object = OpenStruct.new(:source_type => :LANG)
      subject.should_receive(:respond_to?).with('html_markup_html').and_return(true)
      subject.should_receive(:respond_to?).with('html_syntax_highlight_LANG').and_return(true)
      subject.should_receive(:html_syntax_highlight_LANG).and_return("foobar")
        expect(subject.htmlify("<pre><code>!!!LANG\ndef x; end</code></pre>", :html)).to eq '<pre class="code LANG"><code>foobar</code></pre>'
    end

    it "should call html_syntax_highlight_NAME if source starts with !!!NAME" do
      subject.should_receive(:respond_to?).with('html_syntax_highlight_NAME').and_return(true)
      subject.should_receive(:html_syntax_highlight_NAME).and_return("foobar")
        expect(subject.html_syntax_highlight(<<-eof
        !!!NAME
        def x; end
      eof
        )).to eq "foobar"
    end

    it "should not highlight if highlight option is false" do
      subject.options.highlight = false
      subject.should_not_receive(:html_syntax_highlight_ruby)
        expect(subject.html_syntax_highlight('def x; end')).to eq 'def x; end'
    end

    it "should not highlight if there is no highlight method specified by !!!NAME" do
      subject.should_receive(:respond_to?).with('html_syntax_highlight_NAME').and_return(false)
      subject.should_not_receive(:html_syntax_highlight_NAME)
        expect(subject.html_syntax_highlight("!!!NAME\ndef x; end")).to eq "def x; end"
    end

    it "should highlight as ruby if htmlify(text, :ruby) is called" do
      subject.should_receive(:html_syntax_highlight_ruby).with('def x; end').and_return('x')
        expect(subject.htmlify('def x; end', :ruby)).to eq '<pre class="code ruby">x</pre>'
    end

    it "should not prioritize object source type when called directly" do
      subject.should_receive(:html_syntax_highlight_ruby).with('def x; end').and_return('x')
      subject.object = OpenStruct.new(:source_type => :c)
        expect(subject.html_syntax_highlight("def x; end")).to eq "x"
    end

    it "shouldn't escape code snippets twice" do
        expect(subject.htmlify('<pre lang="foo"><code>{"foo" => 1}</code></pre>', :html)).to eq '<pre class="code foo"><code>{&quot;foo&quot; =&gt; 1}</code></pre>'
    end

    it "should highlight source when matching a pre lang= tag" do
        expect(subject.htmlify('<pre lang="foo"><code>x = 1</code></pre>', :html)).to eq '<pre class="code foo"><code>x = 1</code></pre>'
    end

    it "should highlight source when matching a code class= tag" do
        expect(subject.htmlify('<pre><code class="foo">x = 1</code></pre>', :html)).to eq '<pre class="code foo"><code>x = 1</code></pre>'
    end
  end

  describe '#link_url' do
    it "should add target if scheme is provided" do
      link_url("http://url.com").should include(" target=\"_parent\"")
      link_url("https://url.com").should include(" target=\"_parent\"")
      link_url("irc://url.com").should include(" target=\"_parent\"")
      link_url("../not/scheme").should_not include("target")
    end
  end
end
