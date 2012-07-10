require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::CodeObjectList do
  before { Registry.clear }

  it "pushing a value should only allow CodeObjects::Base, String or Symbol" do
    list = CodeObjectList.new(nil)
    lambda { list.push(:hash => 1) }.should raise_error(ArgumentError)
    list << "Test"
    list << :Test2
    list << ModuleObject.new(nil, :YARD)
    list.size.should == 3
  end

  it "added value should be a proxy if parameter was String or Symbol" do
    list = CodeObjectList.new(nil)
    list << "Test"
    list.first.class.should == Proxy
  end

  it "should contain a unique list of objects" do
    obj = ModuleObject.new(nil, :YARD)
    list = CodeObjectList.new(nil)

    list << P(:YARD)
    list << obj
    list.size.should == 1

    list << :Test
    list << "Test"
    list.size.should == 2
  end

  it "should set owner's locale to pushed object" do
    obj = ModuleObject.new(nil, :YARD)
    owner = P(:YARD)
    owner.stub!(:locale).and_return("fr")
    list = CodeObjectList.new(owner)
    list << "Test"
    list[0].locale.should == "fr"
  end
end
