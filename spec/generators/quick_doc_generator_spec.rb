describe YARD::Generators::QuickDocGenerator do
  it "should generate output" do
    Parser::SourceParser.parse_string(<<-eof)
      class A
        # Docstring
        def method1; end
      end
    eof
    g = Generators::QuickDocGenerator.new
  end
end