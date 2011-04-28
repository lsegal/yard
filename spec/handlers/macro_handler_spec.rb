require File.dirname(__FILE__) + '/spec_helper'
require 'ostruct'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}MacroHandler" do
  before(:all) { parse_file :macro_handler_001, __FILE__ }
  
  describe 'Macro expansion' do
    def expand(comments)
      klass = eval("YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}MacroHandler")
      stmt = OpenStruct.new(:comments => comments)
      a = mock(:a)
      a.stub!(:jump).and_return(OpenStruct.new(:source => 'a'))
      b = mock(:b)
      b.stub!(:jump).and_return(OpenStruct.new(:source => 'b'))
      c = mock(:c)
      c.stub!(:jump).and_return(OpenStruct.new(:source => 'c'))
      node_mock = mock(:node)
      node_mock.stub!(:jump).and_return(OpenStruct.new(:source => 'abc'))
      stmt.stub!(:[]).with(0).and_return(node_mock)
      stmt.stub!(:method_name).with(true).and_return('foo')
      stmt.stub!(:parameters).and_return([a, b, c])
      stmt.stub!(:source).and_return('foo :bar, :baz')
      handler = klass.new(nil, stmt)
      handler.instance_variable_set("@docstring", Docstring.new(comments))
      handler.instance_variable_set("@orig_docstring", Docstring.new(comments))
      handler.send(:parse_comments).strip
    end
    
    it "should only expand macros if @macro is present" do
      expand("$1$2$3").should == "$1$2$3"
    end
    
    it "should allow escaping of macro syntax" do
      expand("@macro name\n$1\\$2$3").should == "a$2c"
    end
    
    it "should replace $* with the whole statement" do
      expand("@macro name\n$* ${*}").should == "foo :bar, :baz foo :bar, :baz"
    end
    
    it "should replace $0 with method name" do
      expand("@macro name\n$0 ${0}").should == "foo foo"
    end
    
    it "should replace all $N values with the Nth argument in the method call" do
      expand("@macro name\n$1$2$3${3}\nfoobar").should == "abcc\nfoobar"
    end
    
    it "should replace ${N-M} ranges with N-M arguments (incl. commas)" do
      expand("@macro name\n${1-2}x").should == "a, bx"
    end
    
    it "should handle open ended ranges (${N-})" do
      expand("@macro name\n${2-}").should == "b, c"
    end
    
    it "should handle negative indexes ($-N)" do
      expand("@macro name\n$-1 ${-2-} ${-2--2}").should == "c b, c b"
    end

    it "should handle macro text inside block" do
      expand("@macro name\n  foo$1$2$3\nfoobaz").should == "fooabc\nfoobaz"
    end
  end
  
  it "should create a readable attribute when @attribute r is found" do
    obj = Registry.at('Foo#attr1')
    obj.should_not be_nil
    obj.should be_reader
    obj.tag(:return).types.should == ['Numeric']
    Registry.at('Foo#attr1=').should be_nil
  end

  it "should create a writable attribute when @attribute w is found" do
    obj = Registry.at('Foo#attr2=')
    obj.should_not be_nil
    obj.should be_writer
    Registry.at('Foo#attr2').should be_nil
  end
  
  it "should default to readwrite @attribute" do
    obj = Registry.at('Foo#attr3')
    obj.should_not be_nil
    obj.should be_reader
    obj = Registry.at('Foo#attr3=')
    obj.should_not be_nil
    obj.should be_writer
  end

  it "should default to creating an instance method for any DSL method with tags" do
    obj = Registry.at('Foo#implicit0')
    obj.should_not be_nil
    obj.docstring.should == "IMPLICIT METHOD!"
    obj.tag(:return).types.should == ['String']
  end
  
  it "should set the method name when using @method" do
    obj = Registry.at('Foo.xyz')
    obj.should_not be_nil
    obj.signature.should == 'def xyz(a, b, c)'
    obj.source.should == 'foo_bar'
    obj.docstring.should == 'The foo method'
  end
  
  it "should allow setting of @scope" do
    Registry.at('Foo.xyz').scope.should == :class
  end
  
  it "should allow setting of @visibility" do
    Registry.at('Foo.xyz').visibility.should == :protected
  end
  
  it "should ignore DSL methods without tags" do
    Registry.at('Foo#implicit_invalid').should be_nil
  end
  
  it "should allow creation of macros" do
    macro = Registry.at('.macro.property')
    macro.should_not be_nil
    macro.method_name.should == 'property'
    macro.object.should == Registry.at('Foo')
  end
  
  it "should apply new macro docstrings on new objects" do
    obj = Registry.at('Foo#name')
    obj.should_not be_nil
    obj.source.should == 'property :name, String, :a, :b, :c'
    obj.signature.should == 'def name(a, b, c)'
    obj.docstring.should == 'A property that is awesome.'
    obj.tag(:param).name.should == 'a'
    obj.tag(:param).text.should == 'first parameter'
    obj.tag(:return).types.should == ['String']
    obj.tag(:return).text.should == 'the property name'
  end
  
  it "should allow reuse of named macros" do
    obj = Registry.at('Foo#age')
    obj.should_not be_nil
    obj.source.should == 'property :age, Fixnum, :value'
    obj.signature.should == 'def age(value)'
    obj.docstring.should == 'A property that is awesome.'
    obj.tag(:param).name.should == 'value'
    obj.tag(:param).text.should == 'first parameter'
    obj.tag(:return).types.should == ['Fixnum']
    obj.tag(:return).text.should == 'the property age'
  end
  
  it "should use implicitly named macros" do
    macro = Registry.at('.macro.parser')
    macro.raw_data.should == "@method $1(opts = {})\n@return NOTHING!"
    macro.should_not be_nil
    obj = Registry.at('Foo#c_parser')
    obj.should_not be_nil
    obj.docstring.should == ""
    obj.signature.should == "def c_parser(opts = {})"
    obj.docstring.tag(:return).text.should == "NOTHING!"
  end
  
  it "should only use implicit macros on methods defined in inherited hierarchy" do
    Registry.at('Bar#x_parser').should be_nil
    Registry.at('Baz#y_parser').should_not be_nil
  end
end