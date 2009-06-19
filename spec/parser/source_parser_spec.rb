require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe YARD::Parser::SourceParser do
  before do 
    Registry.clear
  end
  
  describe '#parse_string' do
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
  end

  describe '#parse' do
    it "should parse a basic Ruby file" do
      parse_file :example1, __FILE__
      Registry.at(:Hello).should_not == nil
      Registry.at("Hello::Hi#me").should_not == nil
      Registry.at("Hello::Hi#me").docstring.should == "Docstring"
    end
  
    it "should parse a set of file globs" do
      Dir.should_receive(:[]).with('lib/**/*.rb')
      YARD.parse('lib/**/*.rb')
    end
  
    it "should parse a set of absolute paths" do
      Dir.should_not_receive(:[])
      IO.should_receive(:read).with('/path/to/file').and_return("")
      YARD.parse('/path/to/file')
    end

    it "should parse files with '*' in them as globs and others as absolute paths" do
      Dir.should_receive(:[]).with('*.rb').and_return(['a.rb', 'b.rb'])
      IO.should_receive(:read).with('/path/to/file').and_return("")
      IO.should_receive(:read).with('a.rb').and_return("")
      IO.should_receive(:read).with('b.rb').and_return("")
      YARD.parse ['/path/to/file', '*.rb']
    end
  end
  
  describe '#parse_in_order' do
    def in_order_parse(*files)
      paths = files.map {|f| File.join(File.dirname(__FILE__), 'examples', f.to_s + '.rb.txt') }
      YARD::Parser::SourceParser.parse(paths, Logger::DEBUG)
    end
    
    it "should attempt to parse files in order" do
      msgs = []
      log.should_receive(:debug) {|m| msgs << m }.at_least(:once)
      in_order_parse 'parse_in_order_001', 'parse_in_order_002'
      msgs[1].should =~ /Processing .+parse_in_order_001.+/
      msgs[2].should =~ /Missing object MyModule/
      msgs[3].should =~ /Processing .+parse_in_order_002.+/
      msgs[4].should =~ /Re-processing .+parse_in_order_001.+/
      msgs[5].should =~ /Object MyModule successfully resolved/
    end
  end
end