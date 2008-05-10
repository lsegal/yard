require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Parser::SourceParser do
  def parse_file(file)
    path = File.join(File.dirname(__FILE__), 'examples', file.to_s + '.rb.txt')
    YARD::Parser::SourceParser.parse(path)
  end
  
  # Need to remove all TestHandlers from the handler specs *HACK*
  before { Handlers::Base.clear_subclasses }
  
  it "should parse basic Ruby code" do
    YARD::Parser::SourceParser.parse_string(<<-eof)
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
end