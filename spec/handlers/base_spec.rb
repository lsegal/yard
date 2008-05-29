require File.dirname(__FILE__) + '/spec_helper'

include Parser

describe YARD::Handlers::Base do
  before do
    Handlers::Base.stub!(:inherited)
  end
  
  it "should keep track of subclasses" do
    Handlers::Base.should_receive(:inherited)
    class TestHandler < Handlers::Base; end
  end
  
  it "should handle a string input" do
    class TestStringHandler < Handlers::Base
      handles "hello"
    end

    t = RubyLex::Token.new(0, 0)
    t.set_text "hello"
    TestStringHandler.handles?(TokenList.new([t])).should == true
    
    t.set_text "nothello"
    TestStringHandler.handles?(TokenList.new([t])).should == false
  end
  
  it "should handle regex input" do
    class TestRegexHandler < Handlers::Base
      handles /^nothello$/
    end

    t = RubyToken::TkVal.new(0, 0, "nothello")
    TestRegexHandler.handles?(TokenList.new([t])).should == true

    t.set_text "nothello hello"
    TestRegexHandler.handles?(TokenList.new([t])).should == false
  end

  it "should handle token input" do
    class TestTokenHandler < Handlers::Base
      handles RubyToken::TkMODULE
    end

    mod = RubyToken::TkMODULE.new(0, 0, "module")
    tkif = RubyToken::TkIF.new(0, 0, "if")
    TestTokenHandler.handles?(TokenList.new([mod])).should == true
    TestTokenHandler.handles?(TokenList.new([tkif])).should == false
  end
  
  it "should raise NotImplementedError if process is called on a class with no #process" do
    class TestNotImplementedHandler < Handlers::Base
      handles RubyToken::TkMODULE
    end
    
    lambda { TestNotImplementedHandler.new(0, 0).process }.should raise_error(NotImplementedError)
  end
end