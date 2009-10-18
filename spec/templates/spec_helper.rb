require File.dirname(__FILE__) + '/../spec_helper'

include YARD::Templates

def text_equals(result, expected_example)
  text_equals_string(result, example(expected_example, :txt))
end

def text_equals_string(result, expected)
  result.should == expected
end

def html_equals(result, expected_example)
  html_equals_string(result, example(expected_example))
end

def html_equals_string(result, expected)
  [expected, result].each do |value|
    value.gsub!(/(>)\s+|\s+(<)/, '\1\2')
    value.strip!
  end
  result.should == expected
end

def example(filename, ext = 'html')
  File.read(File.join(File.dirname(__FILE__), 'examples', "#{filename}.#{ext}"))
end

module YARD::Templates::Engine
  class << self
    public :find_template_paths
  end
end
