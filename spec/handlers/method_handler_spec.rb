require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}MethodHandler" do
  before(:all) do
    log.enter_level(Logger::ERROR) do
      parse_file :method_handler_001, __FILE__
    end
  end

  it "should add methods to parent's #meths list" do
    P(:Foo).meths.should include(P("Foo#method1"))
  end

  it "should parse/add class methods (self.method2)" do
    P(:Foo).meths.should include(P("Foo.method2"))
  end

  it "should parse/add class methods from other namespaces (String.hello)" do
    P("String.hello").should be_instance_of(CodeObjects::MethodObject)
  end

  [:[], :[]=, :allowed?, :/, :=~, :==, :`, :|, :*, :&, :%, :'^', :-@, :+@, :'~@'].each do |name|
    it "should allow valid method #{name}" do
      Registry.at("Foo##{name}").should_not be_nil
    end
  end

  it "should allow self.methname" do
    Registry.at("Foo.new").should_not be_nil
  end

  it "should mark dynamic methods as such" do
    expect(P('Foo#dynamic').dynamic?).to eq true
  end

  it "should show that a method is explicitly defined (if it was originally defined implicitly by attribute)" do
     expect(P('Foo#method1').is_explicit?).to eq true
  end

  it "should handle parameters" do
     expect(P('Foo#[]').parameters).to eq [['key', "'default'"]]
     expect(P('Foo#/').parameters).to eq [['x', "File.new('x', 'w')"], ['y', '2']]
  end

  it "should handle opts = {} as parameter" do
     expect(P('Foo#optsmeth').parameters).to eq [['x', nil], ['opts', '{}']]
  end

  it "should handle &block as parameter" do
     expect(P('Foo#blockmeth').parameters).to eq [['x', nil], ['&block', nil]]
  end

  it "should handle overloads" do
    meth = P('Foo#foo')

    o1 = meth.tags(:overload).first
     expect(o1.name).to eq :bar
     expect(o1.parameters).to eq [['a', nil], ['b', "1"]]
     expect(o1.tag(:return).type).to eq "String"

    o2 = meth.tags(:overload)[1]
     expect(o2.name).to eq :baz
     expect(o2.parameters).to eq [['b', nil], ['c', nil]]
     expect(o2.tag(:return).type).to eq "Fixnum"

    o3 = meth.tags(:overload)[2]
     expect(o3.name).to eq :bang
     expect(o3.parameters).to eq [['d', nil], ['e', nil]]
    o3.docstring.should be_empty
    o3.docstring.should be_blank
  end

  it "should set a return tag if not set on #initialize" do
    meth = P('Foo#initialize')

    meth.should have_tag(:return)
     expect(meth.tag(:return).types).to eq ["Foo"]
     expect(meth.tag(:return).text).to eq "a new instance of Foo"
  end

  %w(inherited included method_added method_removed method_undefined).each do |meth|
    it "should set @private tag on #{meth} callback method if no docstring is set" do
      P('Foo.' + meth).should have_tag(:private)
    end
  end

  it "should not set @private tag on extended callback method since docstring is set" do
    P('Foo.extended').should_not have_tag(:private)
  end

  it "should add @return [Boolean] tag to methods ending in ? without return types" do
    meth = P('Foo#boolean?')
    meth.should have_tag(:return)
     expect(meth.tag(:return).types).to eq ['Boolean']
  end

  it "should add Boolean type to return tag without types" do
    meth = P('Foo#boolean2?')
    meth.should have_tag(:return)
     expect(meth.tag(:return).types).to eq ['Boolean']
  end

  it "should not change return type for method ending in ? with return types set" do
    meth = P('Foo#boolean3?')
    meth.should have_tag(:return)
     expect(meth.tag(:return).types).to eq ['NotBoolean', 'nil']
  end

  it "should not change return type for method ending in ? with return types set by @overload" do
    meth = P('Foo#rainy?')
    meth.should have_tag(:overload)
    meth.tag(:overload).should have_tag(:return)
    meth.should_not have_tag(:return)
  end

  it "should add method writer to existing attribute" do
    Registry.at('Foo#attr_name').should be_reader
    Registry.at('Foo#attr_name=').should be_writer
  end

  it "should add method reader to existing attribute" do
    Registry.at('Foo#attr_name2').should be_reader
    Registry.at('Foo#attr_name2=').should be_writer
  end

  it "should generate an options parameter if @option refers to an undocumented parameter" do
    meth = P('Foo#auto_opts')
    meth.should have_tag(:param)
     expect(meth.tag(:param).name).to eq "opts"
     expect(meth.tag(:param).types).to eq ["Hash"]
  end

  it "should raise an undocumentable error when a method is defined on an object instance" do
    undoc_error "error = Foo; def error.at(foo) end"
    Registry.at('error').should be_nil
  end

  it "should allow class method to be defined on constant reference object" do
    Registry.at('Foo.meth_on_const').should_not be_nil
    Registry.at('Foo.meth2_on_const').should_not be_nil
  end

  it "should copy alias information on method (re-)definition to new method" do
    Registry.at('D').aliases.should be_empty
     expect(Registry.at('D#b').is_alias?).to eq false
     expect(Registry.at('D#a').is_alias?).to eq false
  end

  it "should add macros for class methods" do
    macro = CodeObjects::MacroObject.find('prop')
    macro.should_not be_nil
     expect(macro.macro_data).to eq "@!method $1(value)\n$3\n@return [$2]"
     expect(macro.method_object).to eq Registry.at('E.property')
    macro.should be_attached
    obj = Registry.at('E#foo')
    obj.should_not be_nil
     expect(obj.docstring).to eq 'create a foo'
     expect(obj.signature).to eq 'def foo(value)'
     expect(obj.tag(:return).types).to eq ['String']
  end

  it "should handle macros on any object" do
    macro = CodeObjects::MacroObject.find('xyz')
    macro.should_not be_nil
     expect(macro.macro_data).to eq '@!method $1'
  end

  it "should skip macros on instance methods" do
    Registry.at('E#a').should be_nil
  end

  it "should warn if the macro name is invalid" do
    log.should_receive(:warn).with(/Invalid directive.*@!macro/)
    YARD.parse_string "class Foo\n# @!macro\ndef self.foo; end\nend"
  end

  it "should handle 'def end' methods" do
    obj = Registry.at('F::A#foo')
    obj.should_not be_nil
    obj = Registry.at('F::A#bar')
    obj.should_not be_nil
     expect(obj.docstring).to eq 'PASS'
  end
end
