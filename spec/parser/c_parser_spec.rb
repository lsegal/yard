require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe YARD::Parser::CParser do
  before(:all) do
    file = File.join(File.dirname(__FILE__), 'examples', 'array.c.txt')
    @parser = Parser::CParser.new(IO.read(file)).parse
  end
  
  describe '#parse' do
    it "should parse Array class" do
      obj = YARD::Registry.at('Array')
      obj.should_not be_nil
      obj.docstring.should_not be_blank
    end
    
    it "should parse method" do
      obj = YARD::Registry.at('Array#initialize')
      obj.docstring.should_not be_blank
      obj.tags(:overload).size.should > 1
    end
  end
end