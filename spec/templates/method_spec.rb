require File.dirname(__FILE__) + '/spec_helper'

describe Engine.template(:default, :method) do
  before { Registry.clear }
  
  describe 'regular (deprecated) method' do
    before do
      YARD.parse_string <<-'eof'
        private
        # Comments
        # @param [String] x the x argument
        # @return [String] the result
        # @raise [Exception] hi!
        # @deprecated for great justice
        def m(x) end
        alias x m
      eof
    end
    
    it "should render html format correctly" do
      html_equals(Registry.at('#m').format(:format => :html, :no_highlight => true), :method001)
    end
    
    it "should render text format correctly" do
      text_equals(Registry.at('#m').format, :method001)
    end
  end
  
  describe 'method with 1 overload' do
    before do
      YARD.parse_string <<-'eof'
        private
        # Comments
        # @overload m(x, y)
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        def m(x) end
      eof
    end
    
    it "should render html format correctly" do
      html_equals(Registry.at('#m').format(:format => :html, :no_highlight => true), :method002)
    end

    it "should render text format correctly" do
      text_equals(Registry.at('#m').format, :method002)
    end
  end
  
  describe 'method with 2 overloads' do
    before do
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
    end
    
    it "should render html format correctly" do
      html_equals(Registry.at('#m').format(:format => :html, :no_highlight => true), :method003)
    end

    it "should render text format correctly" do
      text_equals(Registry.at('#m').format, :method003)
    end
  end
end