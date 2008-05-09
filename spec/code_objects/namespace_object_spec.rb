require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::NamespaceObject do
  before { @yard = NamespaceObject.new(nil, :YARD) }

  it "#add_mixin should only allow NamespaceOject, String or Symbol" do
    lambda { @yard.add_mixin(:hash => 1) }.should raise_error(ArgumentError)
    @yard.add_mixin "Test"
    @yard.add_mixin @yard
    @yard.mixins.size.should == 2
  end
  
  it "#add_mixin should make new mixin a proxy if parameter is not a NamespaceObject" do
    @yard.add_mixin "Test"
    @yard.mixins.first.class.should == Proxy
  end
end