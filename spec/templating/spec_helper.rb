require File.dirname(__FILE__) + '/../spec_helper'

def html_equals(result, expected)
  [expected, result].each do |value|
    value.gsub!(/\s+/, ' ')
    value.gsub!(/(>)\s+|\s+(<)/, '\1\2')
    value.strip!
  end
  result.should == expected
end
