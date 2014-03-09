require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}PrivateClassMethodHandler" do
  before(:all) { parse_file :private_class_method_handler_001, __FILE__ }

  it "should handle private_class_method statement" do
    Registry.at('A.c').visibility.should == :private
    Registry.at('A.d').visibility.should == :private
  end

  it "should fail if method can't be recognized" do
    undoc_error 'class Foo2; private_class_method :x; end'
  end
end
