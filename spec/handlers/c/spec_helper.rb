require File.dirname(__FILE__) + "/../spec_helper"

def parse(src)
  YARD::Registry.clear
  YARD::Parser::SourceParser.parse_string(src, :c)
end
