require File.dirname(__FILE__) + '/spec_helper'

describe Engine.template(:default, :docstring) do
  before do
    YARD.parse_string <<-'eof'
      private
      # Comments
      # @author Test
      # @version 1.0
      # @see A
      # @see http://example.com Example
      class A < B
        # HI
        def method_missing(*args) end
        # @deprecated
        def a; end
        def b; end
        
        # constructor method!
        def initialize(test) end
      end
    eof
  end
  
  it "should render correctly" do
    html_equals(Registry.at('A').format(:format => :html), :class001)
  end
end