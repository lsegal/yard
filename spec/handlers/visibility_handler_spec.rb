require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}VisibilityHandler" do
  before { parse_file :visibility_handler_001, __FILE__ }
  
  it "should be able to set visibility to public" do
    Registry.at("Testing#pub").visibility.should == :public
    Registry.at("Testing#pub2").visibility.should == :public
  end
  
  it "should be able to set visibility to private" do
    Registry.at("Testing#priv").visibility.should == :private
  end
  
  it "should be able to set visibility to protected" do
    Registry.at("Testing#prot").visibility.should == :protected
  end
  
  it "should support parameters and only set visibility on those methods" do
    Registry['Testing#notpriv'].visibility.should == :public
    Registry['Testing#notpriv2'].visibility.should == :public
    Registry['Testing#notpriv?'].visibility.should == :public
  end
end