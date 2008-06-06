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
  
  c = self.class.described_type.new(mock, Parser::StatementList.new(code).first)
  lambda { c.process }.should raise_error(UndocumentableError)
end