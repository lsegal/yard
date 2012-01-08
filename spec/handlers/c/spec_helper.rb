require File.dirname(__FILE__) + "/../spec_helper"

def parse(src)
  YARD::Registry.clear
  YARD.parse_string(src, :c)
end

def parse_init(src)
  YARD::Registry.clear
  YARD.parse_string("void Init_Foo() {\n#{src}\n}", :c)
end
