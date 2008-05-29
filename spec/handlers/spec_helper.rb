require File.join(File.dirname(__FILE__), "..", "spec_helper")

include Handlers

def undoc_error(code)
  c = self.class.described_type.new(nil, Parser::StatementList.new(code).first)
  lambda { c.process }.should raise_error(UndocumentableError)
end