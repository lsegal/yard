require File.dirname(__FILE__) + '/spec_helper'
require 'ostruct'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}DSLHandler" do
  before(:all) { parse_file :dsl_handler_001, __FILE__ }

  it "should create a readable attribute when @!attribute r is found" do
    obj = Registry.at('Foo#attr1')
    expect(obj).to_not be_nil
    expect(obj).to be_reader
    expect(obj.tag(:return).types).to eq ['Numeric']
    expect(Registry.at('Foo#attr1=')).to be_nil
  end

  it "should create a writable attribute when @!attribute w is found" do
    obj = Registry.at('Foo#attr2=')
    expect(obj).to_not be_nil
    expect(obj).to be_writer
    expect(Registry.at('Foo#attr2')).to be_nil
  end

  it "should default to readwrite @!attribute" do
    obj = Registry.at('Foo#attr3')
    expect(obj).to_not be_nil
    expect(obj).to be_reader
    obj = Registry.at('Foo#attr3=')
    expect(obj).to_not be_nil
    expect(obj).to be_writer
  end

  it "should allow @!attribute to define alternate method name" do
    expect(Registry.at('Foo#attr4')).to be_nil
    expect(Registry.at('Foo#custom')).to_not be_nil
  end

  it "should default to creating an instance method for any DSL method with special tags" do
    obj = Registry.at('Foo#implicit0')
    expect(obj).to_not be_nil
    expect(obj.docstring).to eq "IMPLICIT METHOD!"
    expect(obj.tag(:return).types).to eq ['String']
  end

  it "should recognize implicit docstring when it has scope tag" do
    obj = Registry.at("Foo.implicit1")
    expect(obj).to_not be_nil
    expect(obj.scope).to eq :class
  end

  it "should recognize implicit docstring when it has visibility tag" do
    obj = Registry.at("Foo#implicit2")
    expect(obj).to_not be_nil
    expect(obj.visibility).to eq :protected
  end

  it "should not recognize implicit docstring with any other normal tag" do
    obj = Registry.at('Foo#implicit_invalid3')
    expect(obj).to be_nil
  end

  it "should set the method name when using @!method" do
    obj = Registry.at('Foo.xyz')
    expect(obj).to_not be_nil
    expect(obj.signature).to eq 'def xyz(a, b, c)'
    expect(obj.parameters).to eq [['a', nil], ['b', nil], ['c', nil]]
    expect(obj.source).to eq 'foo_bar'
    expect(obj.docstring).to eq 'The foo method'
  end

  it "should allow setting of @!scope" do
    expect(Registry.at('Foo.xyz').scope).to eq :class
  end

  it "should create module function if @!scope is module" do
    mod_c = Registry.at('Foo.modfunc1')
    mod_i = Registry.at('Foo#modfunc1')
    expect(mod_c.scope).to eq :class
    expect(mod_i.visibility).to eq :private
  end

  it "should allow setting of @!visibility" do
    expect(Registry.at('Foo.xyz').visibility).to eq :protected
  end

  it "should ignore DSL methods without tags" do
    expect(Registry.at('Foo#implicit_invalid')).to be_nil
  end

  it "should accept a DSL method without tags if it has hash_flag (##)" do
    expect(Registry.at('Foo#implicit_valid')).to_not be_nil
    expect(Registry.at('Foo#implicit_invalid2')).to be_nil
  end

  it "should allow creation of macros" do
    macro = CodeObjects::MacroObject.find('property')
    expect(macro).to_not be_nil
    expect(macro).to_not be_attached
    expect(macro.method_object).to be_nil
  end

  it "should handle macros with no parameters to expand" do
    expect(Registry.at('Foo#none')).to_not be_nil
    expect(Registry.at('Baz#none').signature).to eq 'def none(foo, bar)'
  end

  it "should expand $N on method definitions" do
    expect(Registry.at('Foo#regular_meth').docstring).to eq 'a b c'
  end

  it "should apply new macro docstrings on new objects" do
    obj = Registry.at('Foo#name')
    expect(obj).to_not be_nil
    expect(obj.source).to eq 'property :name, String, :a, :b, :c'
    expect(obj.signature).to eq 'def name(a, b, c)'
    expect(obj.docstring).to eq 'A property that is awesome.'
    expect(obj.tag(:param).name).to eq 'a'
    expect(obj.tag(:param).text).to eq 'first parameter'
    expect(obj.tag(:return).types).to eq ['String']
    expect(obj.tag(:return).text).to eq 'the property name'
  end

  it "should allow reuse of named macros" do
    obj = Registry.at('Foo#age')
    expect(obj).to_not be_nil
    expect(obj.source).to eq 'property :age, Fixnum, :value'
    expect(obj.signature).to eq 'def age(value)'
    expect(obj.docstring).to eq 'A property that is awesome.'
    expect(obj.tag(:param).name).to eq 'value'
    expect(obj.tag(:param).text).to eq 'first parameter'
    expect(obj.tag(:return).types).to eq ['Fixnum']
    expect(obj.tag(:return).text).to eq 'the property age'
  end

  it "should know about method information on DSL with macro expansion" do
    expect(Registry.at('Foo#right_name')).to_not be_nil
    expect(Registry.at('Foo#right_name').source)
      .to eq 'implicit_with_different_method_name :wrong, :right'
    expect(Registry.at('Foo#wrong_name')).to be_nil
  end

  it "should use attached macros" do
    macro = CodeObjects::MacroObject.find('parser')
    expect(macro.macro_data).to eq "@!method $1(opts = {})\n@return NOTHING!"
    expect(macro).to_not be_nil
    expect(macro).to be_attached
    expect(macro.method_object).to eq P('Foo.parser')
    obj = Registry.at('Foo#c_parser')
    expect(obj).to_not be_nil
    expect(obj.docstring).to eq ""
    expect(obj.signature).to eq "def c_parser(opts = {})"
    expect(obj.docstring.tag(:return).text).to eq "NOTHING!"
  end

  it "should append docstring on DSL method to attached macro" do
    obj = Registry.at('Foo#d_parser')
    expect(obj).to_not be_nil
    expect(obj.docstring).to eq "Another docstring"
    expect(obj.signature).to eq "def d_parser(opts = {})"
    expect(obj.docstring.tag(:return).text).to eq "NOTHING!"
  end

  it "should only use attached macros on methods defined in inherited hierarchy" do
    expect(Registry.at('Bar#x_parser')).to be_nil
    expect(Registry.at('Baz#y_parser')).to_not be_nil
  end

  it "should look through mixins for attached macros" do
    meth = Registry.at('Baz#mixin_method')
    expect(meth).to_not be_nil
    expect(meth.docstring).to eq 'DSL method mixin_method'
  end

  it "should handle top-level DSL methods" do
    obj = Registry.at('#my_other_method')
    expect(obj).to_not be_nil
    expect(obj.docstring).to eq "Docstring for method"
  end

  it "should handle Constant.foo syntax" do
    obj = Registry.at('#beep')
    expect(obj).to_not be_nil
    expect(obj.signature).to eq 'def beep(a, b, c)'
  end

  it "should expand attached macros in first DSL method" do
    expect(Registry.at('DSLMethods#foo').docstring).to eq "Returns String for foo"
    expect(Registry.at('DSLMethods#bar').docstring).to eq "Returns Integer for bar"
  end

  it "should not detect implicit macros with invalid method names" do
    undoc_error <<-eof
      ##
      # IMPLICIT METHOD THAT SHOULD
      # NOT BE DETECTED
      dsl_method '/foo/bar'
    eof
  end
end
