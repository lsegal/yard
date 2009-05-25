require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

describe YARD::Parser::Ruby::Legacy::StatementList do
  def stmt(code) YARD::Parser::Ruby::Legacy::StatementList.new(code).first end

  it "should parse dangling block expressions" do
    s = stmt <<-eof
      if
          foo
        puts 'hi'
      end
eof

    s.tokens.to_s.should == "if          foo"
    s.block.to_s.should == "\n        puts 'hi'\n      end\n"

    s = stmt <<-eof
      if foo ||
          bar
        puts 'hi'
      end
eof

    s.tokens.to_s.should == "if foo ||          bar"
    s.block.to_s.should == "\n        puts 'hi'\n      end\n"
  end

  it "should allow semicolons within parentheses" do
    s = stmt "(foo; bar)"

    s.tokens.to_s.should == "(foo; bar)"
    s.block.to_s.should == ""
  end

  it "should allow block statements to be used as part of other block statements" do
    s = stmt "while (foo; bar); foo = 12; end"

    s.tokens.to_s.should == "while (foo; bar)"
    s.block.to_s.should == " foo = 12; end\n"
  end

  it "should allow continued processing after a block" do
    s = stmt "if foo; end.stuff"
    s.tokens.to_s.should == "if foo"
    s.block.to_s.should == " end.stuff\n"

    s = stmt "if foo; end[stuff]"
    s.tokens.to_s.should == "if foo"
    s.block.to_s.should == " end[stuff]\n"

    s = stmt "if foo; end.map do; 123; end"
    s.tokens.to_s.should == "if foo"
    s.block.to_s.should == " end.map do; 123; end\n"
  end

  it "should parse default arguments" do
    s = stmt "def foo(bar, baz = 1, bang = 2); bar; end"
    s.tokens.to_s.should == "def foo(bar, baz = 1, bang = 2)"
    s.block.to_s.should == " bar; end\n"

    s = stmt "def foo bar, baz = 1, bang = 2; bar; end"
    s.tokens.to_s.should == "def foo bar, baz = 1, bang = 2"
    s.block.to_s.should == " bar; end\n"

    s = stmt "def foo bar , baz = 1 , bang = 2; bar; end"
    s.tokens.to_s.should == "def foo bar , baz = 1 , bang = 2"
    s.block.to_s.should == " bar; end\n"
  end

  it "should parse complex default arguments" do
    s = stmt "def foo(bar, baz = File.new(1, 2), bang = 3); bar; end"
    s.tokens.to_s.should == "def foo(bar, baz = File.new(1, 2), bang = 3)"
    s.block.to_s.should == " bar; end\n"

    s = stmt "def foo bar, baz = File.new(1, 2), bang = 3; bar; end"
    s.tokens.to_s.should == "def foo bar, baz = File.new(1, 2), bang = 3"
    s.block.to_s.should == " bar; end\n"

    s = stmt "def foo bar , baz = File.new(1, 2) , bang = 3; bar; end"
    s.tokens.to_s.should == "def foo bar , baz = File.new(1, 2) , bang = 3"
    s.block.to_s.should == " bar; end\n"
  end

  it "should parse blocks with do/end" do
    s = stmt <<-eof
      foo do
        puts 'hi'
      end
    eof

    s.tokens.to_s.should == "foo "
    s.block.to_s.should == "do\n        puts 'hi'\n      end\n"
  end
  
  it "should parse blocks with {}" do
    s = stmt "x { y }"
    s.tokens.to_s.should == "x "
    s.block.to_s.should == "{ y }\n"

    s = stmt "x() { y }"
    s.tokens.to_s.should == "x() "
    s.block.to_s.should == "{ y }\n"
  end
  
  it "should parse blocks with begin/end" do
    s = stmt "begin xyz end"
    s.tokens.to_s.should == ""
    s.block.to_s.should == "begin xyz end\n"
  end
  
  it "should parse nested blocks" do
    s = stmt "foo(:x) { baz(:y) { skippy } }"
    
    s.tokens.to_s.should == "foo(:x) "
    s.block.to_s.should == "{ baz(:y) { skippy } }\n"
  end

  it "should not parse hashes as blocks" do
    s = stmt "x({})"
    s.tokens.to_s.should == "x({})"
    s.block.to_s.should == ""

    s = stmt "x = {}"
    s.tokens.to_s.should == "x = {}"
    s.block.to_s.should == ""

    s = stmt "x(y, {})"
    s.tokens.to_s.should == "x(y, {})"
    s.block.to_s.should == ""
  end

  it "should parse hashes in blocks with {}" do
    s = stmt "x {x = {}}"

    s.tokens.to_s.should == "x "
    s.block.to_s.should == "{x = {}}\n"
  end

  it "should parse blocks with {} in hashes" do
    s = stmt "[:foo, x {}]"

    s.tokens.to_s.should == "[:foo, x {}]"
    s.block.to_s.should == ""
  end
end
