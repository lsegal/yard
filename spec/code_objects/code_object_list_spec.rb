require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::CodeObjectList do
  it "pushing a value should only allow CodeObjects::Base, String or Symbol" do
    list = CodeObjectList.new(nil)
    lambda { list.push(:hash => 1) }.should raise_error(ArgumentError)
    list << "Test"
    list << :Test
    list << ModuleObject.new(nil, :YARD)
    list.size.should == 3
  end
  
  it "added value should be a proxy if parameter was String or Symbol" do
    list = CodeObjectList.new(nil)
    list << "Test"
    list.first.class.should == Proxy
  end
end