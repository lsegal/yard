require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'stringio'

include Handlers

def undoc_error(code)
  lambda { StubbedSourceParser.parse_string(code) }.should raise_error(Parser::UndocumentableError)
end

class StubbedProcessor < Processor
  def process(statements)
    statements.each_with_index do |stmt, index|
      find_handlers(stmt).each do |handler| 
        handler.new(self, stmt).process
      end
    end
  end
end

class StubbedSourceParser < Parser::SourceParser
  self.parser_type = :ruby
  def post_process
    post = StubbedProcessor.new(@file, @load_order_errors, @parser_type)
    post.process(@parser.enumerator)
  end
end
  