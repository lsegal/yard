require File.dirname(__FILE__) + '/spec_helper'

describe Engine.template(:default, :method) do
  before do 
    Registry.clear
    YARD.parse_string <<-'eof'
      module B
        def c; end
        def d; end
      end

      # Comments
      module A
        attr_accessor :attr1
        attr_reader :attr2
        
        def self.a; end
        def a; end
        alias b a
        
        include B
        
        class Q; end
        class X; end
        class Y; end
        module Z; end
      end
    eof
  end

  it "should render html format correctly" do
    html_equals(Registry.at('A').format(:format => :html, :no_highlight => true), :module001)
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
    Registry.at('A').format(:format => :dot, :full => true).should == example(:module001, 'dot')
  end
end