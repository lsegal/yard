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

  it "should render correctly" do
    html_equals(Registry.at('A').format(:format => :html), :module001)
  end
end