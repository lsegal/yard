describe YARD::Parser::SourceParser do
  # Need to remove all TestHandlers from the handler specs *HACK*
  before do 
    Registry.clear
  end
  
  it "should parse basic Ruby code" do
    Parser::SourceParser.parse_string(<<-eof)
      module Hello
        class Hi
          # Doctstring
          def me; "VALUE" end
        end
      end
    eof
    Registry.at(:Hello).should_not == nil
    pending("Class and method not yet implemented") do
      Registry.at("Hello::Hi#me").should_not == nil
      Registry.at("Hello::Hi#me").docstring.should == "Docstring"
    end
  end
  
  it "should parse a basic Ruby file" do
    parse_file :example1, __FILE__
    Registry.at(:Hello).should_not == nil
    pending("Class and method not yet implemented") do
      Registry.at("Hello::Hi#me").should_not == nil
      Registry.at("Hello::Hi#me").docstring.should == "Docstring"
    end
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