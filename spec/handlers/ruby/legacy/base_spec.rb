require File.dirname(__FILE__) + '/../../spec_helper'

include Parser::Ruby::Legacy

describe YARD::Handlers::Ruby::Legacy::Base, "#handles and inheritance" do
  before do
    Handlers::Ruby::Legacy::Base.stub!(:inherited)
    Handlers::Ruby::Legacy::MixinHandler.stub!(:inherited) # fixes a Ruby1.9 issue
    @processor = Handlers::Processor.new(OpenStruct.new(:parser_type => :ruby18))
  end

  after(:all) do
    Handlers::Base.clear_subclasses
  end

  def stmt(string)
    Statement.new(TokenList.new(string))
  end

  it "should only handle Handlers inherited from Ruby::Legacy::Base class" do
    class IgnoredHandler < Handlers::Base
      handles "hello"
    end
    class NotIgnoredHandlerLegacy < Handlers::Ruby::Legacy::Base
      handles "hello"
    end
    Handlers::Base.stub!(:subclasses).and_return [IgnoredHandler, NotIgnoredHandlerLegacy]
    expect(@processor.find_handlers(stmt("hello world"))).to eq [NotIgnoredHandlerLegacy]
  end

  it "should handle a string input" do
    class TestStringHandler < Handlers::Ruby::Legacy::Base
      handles "hello"
    end

    expect(TestStringHandler.handles?(stmt("hello world"))).to be_true
    expect(TestStringHandler.handles?(stmt("nothello world"))).to be_false
  end

  it "should handle regex input" do
    class TestRegexHandler < Handlers::Ruby::Legacy::Base
      handles /^nothello$/
    end

    expect(TestRegexHandler.handles?(stmt("nothello"))).to be_true
    expect(TestRegexHandler.handles?(stmt("not hello hello"))).to be_false
  end

  it "should handle token input" do
    class TestTokenHandler < Handlers::Ruby::Legacy::Base
      handles TkMODULE
    end

    expect(TestTokenHandler.handles?(stmt("module"))).to be_true
    expect(TestTokenHandler.handles?(stmt("if"))).to be_false
  end

  it "should parse a do/end or { } block with #parse_block" do
    class MyBlockHandler < Handlers::Ruby::Legacy::Base
      handles /\AmyMethod\b/
      def process
        parse_block(:owner => "test")
      end
    end

    class MyBlockInnerHandler < Handlers::Ruby::Legacy::Base
      handles "inner"
      def self.reset; @@reached = false end
      def self.reached?; @@reached ||= false end
      def process; @@reached = true end
    end

    Handlers::Base.stub!(:subclasses).and_return [MyBlockHandler, MyBlockInnerHandler]
    Parser::SourceParser.parser_type = :ruby18
    Parser::SourceParser.parse_string "myMethod do inner end"
    expect(MyBlockInnerHandler).to be_reached
    MyBlockInnerHandler.reset
    Parser::SourceParser.parse_string "myMethod { inner }"
    expect(MyBlockInnerHandler).to be_reached
    Parser::SourceParser.parser_type = :ruby
  end
end
