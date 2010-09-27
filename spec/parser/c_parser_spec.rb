require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'continuation' unless RUBY18

describe YARD::Parser::CParser do
  before(:all) do
    file = File.join(File.dirname(__FILE__), 'examples', 'array.c.txt')
    @parser = Parser::CParser.new(IO.read(file)).parse

    override_file = File.join(File.dirname(__FILE__), 'examples', 'override.c.txt')
    @override_parser = Parser::CParser.new(IO.read(override_file)).parse
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

  describe '#find_override_comment' do
    it "should parse GMP::Z class" do
      z = YARD::Registry.at('GMP::Z')
      z.should_not be_nil
      z.docstring.should_not be_blank
    end

    it "should parse GMP::Z methods w/ bodies" do
      add = YARD::Registry.at('GMP::Z#+')
      add.docstring.should_not be_blank
      add.source.should_not be_nil
      add.source.should_not be_empty

      add_self = YARD::Registry.at('GMP::Z#+')
      add_self.docstring.should_not be_blank
      add_self.source.should_not be_nil
      add_self.source.should_not be_empty

      sqrtrem = YARD::Registry.at('GMP::Z#+')
      sqrtrem.docstring.should_not be_blank
      sqrtrem.source.should_not be_nil
      sqrtrem.source.should_not be_empty
    end

    it "should parse GMP::Z methods w/o bodies" do
      neg = YARD::Registry.at('GMP::Z#neg')
      neg.docstring.should_not be_blank
      neg.source.should be_nil

      neg_self = YARD::Registry.at('GMP::Z#neg')
      neg_self.docstring.should_not be_blank
      neg_self.source.should be_nil
    end
  end
end