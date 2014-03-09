require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}PrivateClassMethodHandler" do
  before(:all) { parse_file :private_class_method_handler_001, __FILE__ }

  it "should handle private_class_method statement" do
    Registry.at('A.c').visibility.should == :private
    Registry.at('A.d').visibility.should == :private
  end

  it "should fail if parameter is not String or Symbol" do
    undoc_error 'class Foo; private_class_method "x"; end'
    undoc_error 'class Foo; X = 1; private_class_method X.new("hi"); end'
  end unless LEGACY_PARSER

  it "should fail if method can't be recognized" do
    undoc_error 'class Foo2; private_class_method :x; end'
  end
end
