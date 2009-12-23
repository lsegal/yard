require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Templates::Engine.template(:default, :method) do
  before do 
    Registry.clear
    YARD.parse_string <<-'eof'
      module B
        def c; end
        def d; end
        private
        def e; end
      end

      # Comments
      module A
        attr_accessor :attr1
        attr_reader :attr2
        
        # @overload attr3
        #   @return [String] a string
        # @overload attr3=(value)
        #   @param [String] value sets the string
        #   @return [void]
        attr_accessor :attr3
        
        attr_writer :attr4
        
        def self.a; end
        def a; end
        alias b a

        # @overload test_overload(a)
        #   hello2
        #   @param [String] a hi
        def test_overload(*args) end
          
        # @overload test_multi_overload(a)
        # @overload test_multi_overload(a, b)
        def test_multi_overload(*args) end
          
        # @return [void]
        def void_meth; end
        
        include B
        
        class Y; end
        class Q; end
        class X; end
        module Z; end
        CONSTANT = 'value'
        @@cvar = 'value' # @deprecated
      end
    eof
  end

  it "should render html format correctly" do
    html_equals(Registry.at('A').format(:format => :html, :no_highlight => true, :hide_void_return => true, :visibilities => [:public]), :module001)
  end

  it "should render text format correctly" do
    YARD.parse_string <<-'eof'
      module A
        include D, E, F, A::B::C
      end
    eof

    text_equals(Registry.at('A').format, :module001)
  end
  
  it "should render dot format correctly" do
    Registry.at('A').format(:format => :dot, :dependencies => true, :full => true).should == example(:module001, 'dot')
  end
end