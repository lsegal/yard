require File.dirname(__FILE__) + '/spec_helper'

describe Templates::Engine.template(:default, :method) do
  before { Registry.clear }
  
  describe 'regular (deprecated) method' do
    it "should render correctly" do
      YARD.parse_string <<-'eof'
        private
        # Comments
        # @param [String] x the x argument
        # @return [String] the result
        # @deprecated for great justice
        def m(x) end
        alias x m
      eof

      html_equals(Registry.at('#m').format(:format => :html), :method001)
    end
  end
  
  describe 'method with 1 overload' do
    it "should render correctly" do
      YARD.parse_string <<-'eof'
        private
        # Comments
        # @overload m(x, y)
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        def m(x) end
      eof

      html_equals(Registry.at('#m').format(:format => :html), :method002)
    end
  end
  
  describe 'method with 2 overloads' do
    it "should render correctly" do
      YARD.parse_string <<-'eof'
        private
        # Method comments
        # @overload m(x, y)
        #   Overload docstring
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        # @overload m(x, y, z)
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        #   @param [Boolean] z parameter z
        def m(*args) end
      eof

      html_equals(Registry.at('#m').format(:format => :html), :method003)
    end
  end
end