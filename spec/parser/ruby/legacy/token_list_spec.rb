require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

include YARD::Parser::Ruby::Legacy
include YARD::Parser::Ruby::Legacy::RubyToken

describe YARD::Parser::Ruby::Legacy::TokenList do
  describe  "#initialize / #push" do
    it "should accept a tokenlist (via constructor or push)" do
      lambda { TokenList.new(TokenList.new) }.should_not raise_error(ArgumentError)
      expect(TokenList.new.push(TokenList.new("x = 2")).size).to eq 6
    end

    it "accept a token (via constructor or push)" do
      lambda { TokenList.new(Token.new(0, 0)) }.should_not raise_error(ArgumentError)
      expect(TokenList.new.push(Token.new(0, 0), Token.new(1, 1)).size).to eq 2
    end

    it "should accept a string and parse it as code (via constructor or push)" do
      lambda { TokenList.new("x = 2") }.should_not raise_error(ArgumentError)
      x = TokenList.new
      x.push("x", "=", "2")
      expect(x.size).to eq 6
      expect(x.to_s).to eq "x\n=\n2\n"
    end

    it "should not accept any other input" do
      lambda { TokenList.new(:notcode) }.should raise_error(ArgumentError)
    end

    it "should not interpolate string data" do
      x = TokenList.new('x = "hello #{world}"')
      expect(x.size).to eq 6
      expect(x[4].class).to eq TkDSTRING
      expect(x.to_s).to eq 'x = "hello #{world}"' + "\n"
    end
  end

  describe '#to_s' do
    before do
      @t = TokenList.new
      @t << TkDEF.new(1, 1, "def")
      @t << TkSPACE.new(1, 1)
      @t << TkIDENTIFIER.new(1, 1, "x")
      @t << TkStatementEnd.new(1, 1)
      @t << TkSEMICOLON.new(1, 1) << TkSPACE.new(1, 1)
      @t << TkBlockContents.new(1, 1)
      @t << TkSPACE.new(1, 1) << TkEND.new(1, 1, "end")
      @t[0].set_text "def"
      @t[1].set_text " "
      @t[2].set_text "x"
      @t[4].set_text ";"
      @t[5].set_text " "
      @t[7].set_text " "
      @t[8].set_text "end"
    end

    it "should only show the statement portion of the tokens by default" do
      expect(@t.to_s).to eq "def x"
    end

    it "should show ... for the block token if all of the tokens are shown" do
      expect(@t.to_s(true)).to eq "def x; ... end"
    end

    it "should ignore ... if show_block = false" do
      expect(@t.to_s(true, false)).to eq "def x;  end"
    end
  end
end
