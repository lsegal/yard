require File.dirname(__FILE__) + "/../spec_helper"

def tag_parse(content, object = nil, handler = nil)
  @tag_parser = Tags::TagParser.new
  @tag_parser.parse(content, object, handler)
  @tag_parser
end

describe YARD::Tags::GroupDirective do
  describe '#call' do
    it "should do nothing if handler=nil" do
      tag_parse("@!group foo")
    end

    it "should set group value in parser state (with handler)" do
      handler = OpenStruct.new(:extra_state => OpenStruct.new)
      tag_parse("@!group foo", nil, handler)
      handler.extra_state.group.should == 'foo'
    end
  end
end

describe YARD::Tags::EndGroupDirective do
  describe '#call' do
    it "should do nothing if handler=nil" do
      tag_parse("@!endgroup foo")
    end

    it "should set group value in parser state (with handler)" do
      handler = OpenStruct.new(:extra_state => OpenStruct.new(:group => "foo"))
      tag_parse("@!endgroup", nil, handler)
      handler.extra_state.group.should be_nil
    end
  end
end

describe YARD::Tags::MacroDirective do
  def handler
    OpenStruct.new(:call_params => %w(a b c), 
                   :caller_method => 'foo',
                   :namespace => P('Foo::Bar'),
                   :statement => OpenStruct.new(:source => 'foo :a, :b, :c'))
  end

  after(:all) { Registry.clear }

  describe '#call' do
    it "should define new macro when [new] is provided" do
      tag_parse("@!macro [new] foo\n  foo")
      CodeObjects::MacroObject.find('foo').macro_data.should == 'foo'
    end

    it "should define new macro if text block is provided" do
      tag_parse("@!macro bar\n  bar")
      CodeObjects::MacroObject.find('bar').macro_data.should == 'bar'
    end

    it "should expand macros and return #expanded_text to tag parser" do
      tag_parse("@!macro [new] foo\n  foo")
      tag_parse("@!macro foo").text.should == 'foo'
    end

    it "should allow multiple macros to be expanded" do
      tag_parse("@!macro [new] foo\n  foo")
      tag_parse("@!macro bar\n  bar")
      tag_parse("@!macro foo\n@!macro bar").text.should == "foo\nbar"
    end

    it "should allow anonymous macros" do
      tag_parse("@macro\n  a b c", nil, handler)
      @tag_parser.text.should == 'a b c'
    end

    it "should expand call_params and caller_method using $N when handler is provided" do
      tag_parse("@macro\n  $1 $2 $3", nil, handler)
      @tag_parser.text.should == 'a b c'
    end

    it "should attach macro to method if one exists" do
      tag_parse("@macro [attach] attached\n  $1 $2 $3", nil, handler)
      macro = CodeObjects::MacroObject.find('attached')
      macro.method_object.should == P('Foo::Bar.foo')
    end

    it "should not attempt to expand macro values if handler = nil" do
      tag_parse("@macro [attach] xyz\n  $1 $2 $3")
    end
  end
end

describe YARD::Tags::MethodDirective do
  describe '#call' do
    it "should handle indented block text in @!method" do
      YARD.parse_string <<-eof
        # @!method foo(a)
        #   Docstring here
        #   @return [String] the foo
        # Ignore this
        # @param [String] a
      eof
      foo = Registry.at('#foo')
      foo.docstring.should == "Docstring here"
      foo.docstring.tag(:return).should_not be_nil
      foo.tag(:param).should be_nil
    end

    it "should be able to define multiple @methods in docstring" do
      YARD.parse_string <<-eof
        class Foo
          # @!method foo1
          #   Docstring1
          # @!method foo2
          #   Docstring2
          # @!method foo3
          #   @!scope class
          #   Docstring3
        end
      eof
      foo1 = Registry.at('Foo#foo1')
      foo2 = Registry.at('Foo#foo2')
      foo3 = Registry.at('Foo.foo3')
      foo1.docstring.should == 'Docstring1'
      foo2.docstring.should == 'Docstring2'
      foo3.docstring.should == 'Docstring3'
    end
  end
end

describe YARD::Tags::AttributeDirective do
  describe '#call' do
    it "should handle indented block in @!attribute" do
      YARD.parse_string <<-eof
        # @!attribute foo
        #   Docstring here
        #   @return [String] the foo
        # Ignore this
        # @param [String] a
      eof
      foo = Registry.at('#foo')
      foo.is_attribute?.should == true
      foo.docstring.should == "Docstring here"
      foo.docstring.tag(:return).should_not be_nil
      foo.tag(:param).should be_nil
    end

    it "should be able to define multiple @attributes in docstring" do
      YARD.parse_string <<-eof
        class Foo
          # @!attribute [r] foo1
          #   Docstring1
          # @!attribute [w] foo2
          #   Docstring2
          # @!attribute foo3
          #   @!scope class
          #   Docstring3
        end
      eof
      foo1 = Registry.at('Foo#foo1')
      foo2 = Registry.at('Foo#foo2=')
      foo3 = Registry.at('Foo.foo3')
      foo1.is_attribute?.should == true
      foo2.is_attribute?.should == true
      foo3.is_attribute?.should == true
      foo1.docstring.should == 'Docstring1'
      foo2.docstring.should == 'Docstring2'
      foo3.docstring.should == 'Docstring3'
    end
  end
end

describe YARD::Tags::ScopeDirective do
  describe '#call' do
    it "should set state on tag parser if object = nil" do
      tag_parse("@!scope class")
      @tag_parser.state.scope.should == :class
    end

    it "should set scope on object if object != nil" do
      object = OpenStruct.new(:scope => nil)
      tag_parse("@!scope class", object)
      object.scope.should == :class
    end

    %w(class instance).each do |type|
      it "should allow #{type} as value" do
        tag_parse("@!scope #{type}")
        @tag_parser.state.scope.should == type.to_sym
      end
    end
    
    %w(invalid foo FOO CLASS INSTANCE).each do |type|
      it "should not allow #{type} as value" do
        tag_parse("@!scope #{type}")
        @tag_parser.state.scope.should be_nil
      end
    end
  end
end

describe YARD::Tags::VisibilityDirective do
  describe '#call' do
    it "should set visibility on tag parser if object = nil" do
      tag_parse("@!visibility private")
      @tag_parser.state.visibility.should == :private
    end

    it "should set visibility on object if object != nil" do
      object = OpenStruct.new(:visibility => nil)
      tag_parse("@!scope class", object)
      object.scope.should == :class
    end

    %w(public private protected).each do |type|
      it "should allow #{type} as value" do
        tag_parse("@!visibility #{type}")
        @tag_parser.state.visibility.should == type.to_sym
      end
    end
    
    %w(invalid foo FOO PRIVATE INSTANCE).each do |type|
      it "should not allow #{type} as value" do
        tag_parse("@!visibility #{type}")
        @tag_parser.state.visibility.should be_nil
      end
    end
  end
end
