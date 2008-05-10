require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Parser::SourceParser do
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
end