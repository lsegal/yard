require File.dirname(__FILE__) + '/../spec_helper'

include YARD::Templates

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

def example(filename)
  File.read(File.join(File.dirname(__FILE__), 'examples', "#{filename}.html"))
end
