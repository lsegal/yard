require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}VisibilityHandler" do
  after { Registry.clear }

  def assert_module_function(namespace, name)
    klass = Registry.at("#{namespace}.#{name}")
    instance = Registry.at("#{namespace}##{name}")
    expect(klass).to_not be_nil
    expect(instance).to_not be_nil
    expect(klass).to be_module_function
    expect(instance).to_not be_module_function
    expect(klass.visibility).to eq :public
    expect(instance.visibility).to eq :private
  end

  it "should be able to create a module function with parameters" do
    YARD.parse_string <<-eof
      module Foo
        def bar; end
        def baz; end

        module_function :bar, :baz
      end
    eof
    assert_module_function('Foo', 'bar')
    assert_module_function('Foo', 'baz')
  end

  it "should be able to set scope for duration of block without params" do
    YARD.parse_string <<-eof
      module Foo
        def qux; end

        module_function

        def bar; end
        def baz; end
      end
    eof
    expect(Registry.at('Foo.qux')).to be_nil
    assert_module_function('Foo', 'bar')
    assert_module_function('Foo', 'baz')
  end

  # @bug gh-563
  it "should copy tags to module function properly" do
    YARD.parse_string <<-eof
      module Foo
        # @param [String] foo bar
        # @option foo [String] bar (nil) baz
        # @return [void]
        def bar(foo); end
        module_function :bar
      end
    eof
    assert_module_function('Foo', 'bar')
    o = Registry.at('Foo.bar')
    expect(o.tag(:param).types).to eq ['String']
    expect(o.tag(:param).name).to eq 'foo'
    expect(o.tag(:param).text).to eq 'bar'
    expect(o.tag(:option).name).to eq 'foo'
    expect(o.tag(:option).pair.types).to eq ['String']
    expect(o.tag(:option).pair.defaults).to eq ['nil']
    expect(o.tag(:option).pair.text).to eq 'baz'
    expect(o.tag(:return).types).to eq ['void']
  end

  it "should handle all method names in parameters" do
    YARD.parse_string <<-eof
      module Foo
        def -(t); end
        def ==(other); end
        def a?; end
        module_function :-, '==', :a?
      end
    eof
    assert_module_function('Foo', '-')
    assert_module_function('Foo', '==')
    assert_module_function('Foo', 'a?')
  end

  it "should only accept strings and symbols" do
    YARD.parse_string <<-eof
      module Foo
        module_function name
        module_function *argument
        module_function *(method_call)
      end
    eof
    expect(Registry.at('Foo#name')).to be_nil
    expect(Registry.at('Foo#argument')).to be_nil
    expect(Registry.at('Foo#method_call')).to be_nil
  end

  it "should handle constants passed in as symbols" do
    YARD.parse_string <<-eof
      module Foo
        def Foo; end
        module_function :Foo
      end
    eof
    assert_module_function('Foo', 'Foo')
  end
end
