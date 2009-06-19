require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe YARD::Parser::SourceParser do
  before do 
    Registry.clear
  end
  
  it "should parse basic Ruby code" do
    Parser::SourceParser.parse_string(<<-eof)
      module Hello
        class Hi
          # Docstring
          # Docstring2
          def me; "VALUE" end
        end
      end
    eof
    Registry.at(:Hello).should_not == nil
    Registry.at("Hello::Hi#me").should_not == nil
    Registry.at("Hello::Hi#me").docstring.should == "Docstring\nDocstring2"
    Registry.at("Hello::Hi#me").docstring.line_range.should == (3..4)
  end
  
  it "should parse a basic Ruby file" do
    parse_file :example1, __FILE__
    Registry.at(:Hello).should_not == nil
    Registry.at("Hello::Hi#me").should_not == nil
    Registry.at("Hello::Hi#me").docstring.should == "Docstring"
  end
end