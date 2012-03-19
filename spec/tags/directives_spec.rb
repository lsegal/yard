require File.dirname(__FILE__) + "/../spec_helper"

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
