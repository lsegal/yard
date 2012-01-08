require File.dirname(__FILE__) + "/../spec_helper"

def cparse(src)
  YARD::Registry.clear
  YARD::Parser::SourceParser.parse_string(src, :c)
end
