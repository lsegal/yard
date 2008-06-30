require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe YARD::Parser::StatementList do
  def stmt(code) YARD::Parser::StatementList.new(code).first end
  
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
end