require File.join(File.dirname(__FILE__), '..', 'spec_helper')

include YARD::Parser
include YARD::Parser::RubyToken

describe YARD::Parser::TokenList, "#initialize / #push" do
  it "should accept a tokenlist (via constructor or push)" do
    lambda { TokenList.new(TokenList.new) }.should_not raise_error(ArgumentError)
    TokenList.new.push(TokenList.new("x = 2")).size.should == 6
  end
  
  it "accept a token (via constructor or push)" do
    lambda { TokenList.new(Token.new(0, 0)) }.should_not raise_error(ArgumentError)
    TokenList.new.push(Token.new(0, 0), Token.new(1, 1)).size.should == 2
  end
  
  it "should accept a string and parse it as code (via constructor or push)" do
    lambda { TokenList.new("x = 2") }.should_not raise_error(ArgumentError)
    x = TokenList.new
    x.push("x", "=", "2")
    x.size.should == 6
    x.to_s.should == "x\n=\n2\n"
  end
  
  it "should not accept any other input" do
    lambda { TokenList.new(:notcode) }.should raise_error(ArgumentError)
  end
  
  it "should not interpolate string data" do
    x = TokenList.new('x = "hello #{world}"')
    x.size.should == 6
    x[4].class.should == TkDSTRING
    x.to_s.should == 'x = "hello #{world}"' + "\n"
  end
end