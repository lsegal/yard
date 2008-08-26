require File.join(File.dirname(__FILE__), "..", "spec_helper")

include Handlers

def undoc_error(code)
  mock = mock("parser")
  mock.stub!(:namespace).and_return(Registry.root)
  mock.stub!(:namespace=).and_return nil
  mock.stub!(:owner).and_return(Registry.root)
  mock.stub!(:owner=).and_return nil
  mock.stub!(:scope).and_return(:instance)
  mock.stub!(:scope=).and_return nil
  mock.stub!(:visibility).and_return(:public)
  mock.stub!(:visibility=).and_return nil
  mock.stub!(:file).and_return('<STDIN>')
  mock.stub!(:parse).and_return nil
  mock.stub!(:load_order_errors).and_return false
  
  lambda { MockParser.parse_string(code) }.should raise_error(UndocumentableError)
end

class MockParser
  def self.parse_string(content)
    new.parse(StringIO.new(content))
  end

  attr_reader :file
  attr_accessor :namespace, :visibility, :scope, :owner, :load_order_errors

  def initialize(load_order_errors = false)
    @file = "<STDIN>"
    @namespace = YARD::Registry.root
    @visibility = :public
    @scope = :instance
    @owner = @namespace
    @load_order_errors = load_order_errors
  end
  
  def parse(content = __FILE__)
    case content
    when String
      @file = content
      statements = YARD::Parser::StatementList.new(IO.read(content))
    when YARD::Parser::TokenList
      statements = YARD::Parser::StatementList.new(content)
    when YARD::Parser::StatementList
      statements = content
    else
      if content.respond_to? :read
        statements = YARD::Parser::StatementList.new(content.read)
      else
        raise ArgumentError, "Invalid argument for SourceParser::parse: #{content.inspect}:#{content.class}"
      end
    end

    top_level_parse(statements)
  end

  private

  def top_level_parse(statements)
      statements.each do |stmt|
        find_handlers(stmt).each do |handler| 
          handler.new(self, stmt).process
        end
      end
  end

  def find_handlers(stmt)
    YARD::Handlers::Base.subclasses.find_all {|sub| sub.handles? stmt.tokens }
  end
end