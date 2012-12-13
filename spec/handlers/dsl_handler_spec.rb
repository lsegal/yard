require File.dirname(__FILE__) + '/spec_helper'
require 'ostruct'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}DSLHandler" do
  before(:all) { parse_file :dsl_handler_001, __FILE__ }

  it "should create a readable attribute when @!attribute r is found" do
    obj = Registry.at('Foo#attr1')
    obj.should_not be_nil
    obj.should be_reader
    expect(obj.tag(:return).types).to eq ['Numeric']
    Registry.at('Foo#attr1=').should be_nil
  end

  it "should create a writable attribute when @!attribute w is found" do
    obj = Registry.at('Foo#attr2=')
    obj.should_not be_nil
    obj.should be_writer
    Registry.at('Foo#attr2').should be_nil
  end

  it "should default to readwrite @!attribute" do
    obj = Registry.at('Foo#attr3')
    obj.should_not be_nil
    obj.should be_reader
    obj = Registry.at('Foo#attr3=')
    obj.should_not be_nil
    obj.should be_writer
  end

  it "should allow @!attribute to define alternate method name" do
    Registry.at('Foo#attr4').should be_nil
    Registry.at('Foo#custom').should_not be_nil
  end

  it "should default to creating an instance method for any DSL method with special tags" do
    obj = Registry.at('Foo#implicit0')
    obj.should_not be_nil
    expect(obj.docstring).to eq "IMPLICIT METHOD!"
    expect(obj.tag(:return).types).to eq ['String']
  end

  it "should recognize implicit docstring when it has scope tag" do
    obj = Registry.at("Foo.implicit1")
    obj.should_not be_nil
    expect(obj.scope).to eq :class
  end

  it "should recognize implicit docstring when it has visibility tag" do
    obj = Registry.at("Foo#implicit2")
    obj.should_not be_nil
    expect(obj.visibility).to eq :protected
  end

  it "should not recognize implicit docstring with any other normal tag" do
    obj = Registry.at('Foo#implicit_invalid3')
    obj.should be_nil
  end

  it "should set the method name when using @!method" do
    obj = Registry.at('Foo.xyz')
    obj.should_not be_nil
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
    Registry.at('Foo#implicit_invalid').should be_nil
  end

  it "should accept a DSL method without tags if it has hash_flag (##)" do
    Registry.at('Foo#implicit_valid').should_not be_nil
    Registry.at('Foo#implicit_invalid2').should be_nil
  end

  it "should allow creation of macros" do
    macro = CodeObjects::MacroObject.find('property')
    macro.should_not be_nil
    macro.should_not be_attached
    macro.method_object.should be_nil
  end

  it "should handle macros with no parameters to expand" do
    Registry.at('Foo#none').should_not be_nil
    expect(Registry.at('Baz#none').signature).to eq 'def none(foo, bar)'
  end

  it "should expand $N on method definitions" do
    expect(Registry.at('Foo#regular_meth').docstring).to eq 'a b c'
  end

  it "should apply new macro docstrings on new objects" do
    obj = Registry.at('Foo#name')
    obj.should_not be_nil
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
    obj.should_not be_nil
    expect(obj.source).to eq 'property :age, Fixnum, :value'
    expect(obj.signature).to eq 'def age(value)'
    expect(obj.docstring).to eq 'A property that is awesome.'
    expect(obj.tag(:param).name).to eq 'value'
    expect(obj.tag(:param).text).to eq 'first parameter'
    expect(obj.tag(:return).types).to eq ['Fixnum']
    expect(obj.tag(:return).text).to eq 'the property age'
  end

  it "should know about method information on DSL with macro expansion" do
    Registry.at('Foo#right_name').should_not be_nil
    expect(Registry.at('Foo#right_name').source).to eq 'implicit_with_different_method_name :wrong, :right'
    Registry.at('Foo#wrong_name').should be_nil
  end

  it "should use attached macros" do
    macro = CodeObjects::MacroObject.find('parser')
    expect(macro.macro_data).to eq "@!method $1(opts = {})\n@return NOTHING!"
    macro.should_not be_nil
    macro.should be_attached
    expect(macro.method_object).to eq P('Foo.parser')
    obj = Registry.at('Foo#c_parser')
    obj.should_not be_nil
    expect(obj.docstring).to eq ""
    expect(obj.signature).to eq "def c_parser(opts = {})"
    expect(obj.docstring.tag(:return).text).to eq "NOTHING!"
  end

  it "should append docstring on DSL method to attached macro" do
    obj = Registry.at('Foo#d_parser')
    obj.should_not be_nil
    expect(obj.docstring).to eq "Another docstring"
    expect(obj.signature).to eq "def d_parser(opts = {})"
    expect(obj.docstring.tag(:return).text).to eq "NOTHING!"
  end

  it "should only use attached macros on methods defined in inherited hierarchy" do
    Registry.at('Bar#x_parser').should be_nil
    Registry.at('Baz#y_parser').should_not be_nil
  end

  it "should handle top-level DSL methods" do
    obj = Registry.at('#my_other_method')
    obj.should_not be_nil
    expect(obj.docstring).to eq "Docstring for method"
  end

  it "should handle Constant.foo syntax" do
    obj = Registry.at('#beep')
    obj.should_not be_nil
    expect(obj.signature).to eq 'def beep(a, b, c)'
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
