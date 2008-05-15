describe YARD::Generators::QuickDocGenerator do
  before { Registry.clear }
  
  it "should call all sections" do
    Parser::SourceParser.parse_string(<<-eof)
      class A
        # Docstring
        def method1; end
      end
    eof
    g = Generators::QuickDocGenerator.new
  end
end