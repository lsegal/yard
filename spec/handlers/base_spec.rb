require File.dirname(__FILE__) + '/spec_helper'

class TestHandler < Handlers::Base
end

class TestStringHandler < Handlers::Base
  handles "hello"
end

class TestTokenHandler < Handlers::Base
  handles Parser::RubyToken::TkMODULE
end

class TestRegexHandler < Handlers::Base
  handles /^nothello$/
end

include Parser

describe YARD::Handlers::Base do
  it "should keep track of subclasses" do
    Handlers::Base.subclasses.include?(TestHandler).should == true
  end
  
  it "should handle a string input" do
    t = RubyLex::Token.new(0, 0)
    t.set_text "hello"
    TestStringHandler.handles?(TokenList.new([t])).should == true
    
    t.set_text "nothello"
    TestStringHandler.handles?(TokenList.new([t])).should == false
  end
  
  it "should handle regex input" do
    t = RubyToken::TkVal.new(0, 0, "nothello")
    TestRegexHandler.handles?(TokenList.new([t])).should == true

    t.set_text "nothello hello"
    TestRegexHandler.handles?(TokenList.new([t])).should == false
  end

  it "should handle token input" do
    mod = RubyToken::TkMODULE.new(0, 0, "module")
    tkif = RubyToken::TkIF.new(0, 0, "if")
    TestTokenHandler.handles?(TokenList.new([mod])).should == true
    TestTokenHandler.handles?(TokenList.new([tkif])).should == false
  end
  
  it "should reset visibility/scope when a namespace is entered" 
  
end