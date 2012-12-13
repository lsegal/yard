require File.dirname(__FILE__) + '/spec_helper'

include Parser::Ruby::Legacy

describe YARD::Handlers::Ruby::Legacy::Base, "#tokval" do

  before { @handler = Handlers::Ruby::Legacy::Base.new(nil, nil) }

  def tokval(code, *types)
    @handler.send(:tokval, TokenList.new(code).first, *types)
  end

  it "should return the String's value without quotes" do
    expect(tokval('"hello"')).to eq "hello"
  end

  it "should not allow interpolated strings with TkSTRING" do
    tokval('"#{c}"', RubyToken::TkSTRING).should be_nil
  end

  it "should return a Symbol's value as a String (as if it was done via :name.to_sym)" do
    expect(tokval(':sym')).to eq :sym
  end

  it "should return nil for any non accepted type" do
    tokval('identifier').should be_nil
    tokval(':sym', RubyToken::TkId).should be_nil
  end

  it "should accept TkVal tokens by default" do
    expect(tokval('2.5')).to eq 2.5
    expect(tokval(':sym')).to eq :sym
  end

  it "should accept any ID type if TkId is set" do
    expect(tokval('variable', RubyToken::TkId)).to eq "variable"
    expect(tokval('CONSTANT', RubyToken::TkId)).to eq "CONSTANT"
  end

  it "should allow extra token types to be accepted" do
    expect(tokval('2.5', RubyToken::TkFLOAT)).to eq 2.5
    tokval('2', RubyToken::TkFLOAT).should be_nil
    tokval(':symbol', RubyToken::TkFLOAT).should be_nil
  end

  it "should allow :string for any string type" do
    expect(tokval('"hello"', :string)).to eq "hello"
    expect(tokval('"#{c}"', :string)).to eq '#{c}'
  end

  it "should not include interpolated strings when using :attr" do
    tokval('"#{c}"', :attr).should be_nil
  end

  it "should allow any number type with :number" do
    expect(tokval('2.5', :number)).to eq 2.5
    expect(tokval('2', :number)).to eq 2
  end

  it "should should allow method names with :identifier" do
    expect(tokval('methodname?', :identifier)).to eq "methodname?"
  end

  #it "should obey documentation expectations" do docspec end
end

describe YARD::Handlers::Base, "#tokval_list" do
  before { @handler = Handlers::Ruby::Legacy::Base.new(nil, nil) }

  def tokval_list(code, *types)
    @handler.send(:tokval_list, TokenList.new(code), *types)
  end

  it "should return the list of tokvalues" do
    expect(tokval_list(":a, :b, \"\#{c}\", 'd'", :attr)).to eq [:a, :b, 'd']
    tokval_list(":a, :b, File.read(\"\#{c}\", ['w']), :d",
      RubyToken::Token).should  == [:a, :b, 'File.read("#{c}", [\'w\'])', :d]
  end

  it "should try to skip any invalid tokens" do
    expect(tokval_list(":a, :b, \"\#{c}\", :d", :attr)).to eq [:a, :b, :d]
    expect(tokval_list(":a, :b, File.read(\"\#{c}\", 'w', File.open { }), :d", :attr)).to eq [:a, :b, :d]
    tokval_list("CONST1, identifier, File.read(\"\#{c}\", 'w', File.open { }), CONST2",
      RubyToken::TkId).should  == ['CONST1', 'identifier', 'CONST2']
  end

  it "should ignore a token if another invalid token is read before a comma" do
    expect(tokval_list(":a, :b XYZ, :c", RubyToken::TkSYMBOL)).to eq [:a, :c]
  end

  it "should stop on most keywords" do
    expect(tokval_list(':a rescue :x == 5', RubyToken::Token)).to eq [:a]
  end

  it "should handle ignore parentheses that begin the token list" do
    expect(tokval_list('(:a, :b, :c)', :attr)).to eq [:a, :b, :c]
  end

  it "should end when a closing parenthesis was found" do
    expect(tokval_list(':a, :b, :c), :d', :attr)).to eq [:a, :b, :c]
  end

  it "should ignore parentheses around items in a list" do
    expect(tokval_list(':a, (:b), :c, (:d TEST), :e, [:f], :g', :attr)).to eq [:a, :b, :c, :e, :g]
    expect(tokval_list(':a, (((:f)))', :attr)).to eq [:a, :f]
    expect(tokval_list(':a, ([:f]), :c)', RubyToken::Token)).to eq [:a, '[:f]', :c]
  end

  it "should not stop on a true/false/self keyword (cannot handle nil)" do
    expect(tokval_list(':a, true, :b, self, false, :c, nil, File, super, if, XYZ',
                       RubyToken::Token)).to eq [:a, true, :b, 'self', false, :c, 'File', 'super']
  end

  it "should ignore invalid commas" do
    expect(tokval_list(":a, :b, , :d")).to eq [:a, :b, :d]
  end

  it "should return an empty list if no matches were found" do
    expect(tokval_list('attr_accessor :x')).to eq []
  end

  it "should treat {} as a valid value" do
    # FIXME: tokval_list destroys extra spaces surrounding the '=' in
    #        this situation. This is technically a design flaw of the
    #        tokval parser, but this is now the expected behaviour.
    expect(tokval_list("opts = {}", :all)).to eq ["opts={}"]
  end
end
