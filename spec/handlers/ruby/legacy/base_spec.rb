require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../../../lib/yard/parser/ruby/legacy/ruby_lex'
require File.dirname(__FILE__) + '/../../../../lib/yard/handlers/ruby/legacy/base'

include Parser::Ruby::Legacy

describe YARD::Handlers::Ruby::Legacy::Base, "#handles and inheritance" do
  before do
    Handlers::Ruby::Legacy::Base.stub!(:inherited)
    @processor = Handlers::Processor.new(nil, false, :ruby18)
  end
  
  def stmt(string)
    Statement.new(TokenList.new(string))
  end
  
  it "should only handle Handlers inherited from Ruby::Legacy::Base class" do
    class IgnoredHandler < Handlers::Base
      handles "hello"
    end
    class NotIgnoredHandler < Handlers::Ruby::Legacy::Base
      handles "hello"
    end
    Handlers::Base.stub!(:subclasses).and_return [IgnoredHandler, NotIgnoredHandler]
    @processor.find_handlers(stmt("hello world")).should == [NotIgnoredHandler]
  end

  it "should handle a string input" do
    class TestStringHandler < Handlers::Ruby::Legacy::Base
      handles "hello"
    end

    TestStringHandler.handles?(stmt("hello world")).should be_true
    TestStringHandler.handles?(stmt("nothello world")).should be_false
  end

  it "should handle regex input" do
    class TestRegexHandler < Handlers::Ruby::Legacy::Base
      handles /^nothello$/
    end

    TestRegexHandler.handles?(stmt("nothello")).should be_true
    TestRegexHandler.handles?(stmt("not hello hello")).should be_false
  end

  it "should handle token input" do
    class TestTokenHandler < Handlers::Ruby::Legacy::Base
      handles TkMODULE
    end

    TestTokenHandler.handles?(stmt("module")).should be_true
    TestTokenHandler.handles?(stmt("if")).should be_false
  end
end