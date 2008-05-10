require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Parser::SourceParser do
  # Need to remove all TestHandlers from the handler specs *HACK*
  before { Handlers::Base.clear_subclasses }
  
  it "should parse basic Ruby code" do
    Parser::SourceParser.parse_string(<<-eof)
      module Hello
        class Hi
          def me; "VALUE" end
        end
      end
    eof
  end
  
  it "should parse a basic Ruby file" do
    parse_file :example1
  end
  
  it "should start with public visibility" do
    p = Parser::SourceParser.new
    p.visibility.should == :public
  end
  
  it "should start in instance scope" do
    p = Parser::SourceParser.new
    p.scope.should == :instance
  end
  
  it "should start in root namespace" do
    p = Parser::SourceParser.new
    p.namespace.should == Registry.root
  end
end