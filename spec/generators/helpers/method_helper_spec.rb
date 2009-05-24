require File.dirname(__FILE__) + '/../../spec_helper'

describe YARD::Generators::Helpers::MethodHelper, '#format_overload' do
  include YARD::Generators::Helpers::BaseHelper
  include YARD::Generators::Helpers::MethodHelper
  
  it "should format overload signature properly" do
    params = "(a, b = 1, &block) {|x, y| ... }"
    overload = mock(:overload)

    overload.stub!(:signature).and_return("def mymethod#{params}")
    format_overload(overload).should == params

    overload.stub!(:signature).and_return("def []#{params}")
    format_overload(overload).should == params

    overload.stub!(:signature).and_return("justmeth?#{params}")
    format_overload(overload).should == params
  end
end
