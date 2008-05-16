require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::NamespaceObject do
  it "should respond to #child with the object name passed in" do
    obj = NamespaceObject.new(nil, :YARD)
    other = NamespaceObject.new(obj, :Other)
    obj.child(:Other).should == other
    obj.child('Other').should == other
  end
end