require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::CodeObjectList do
  before { Registry.clear }

  it "pushing a value should only allow CodeObjects::Base, String or Symbol" do
    list = CodeObjectList.new(nil)
    lambda { list.push(:hash => 1) }.should raise_error(ArgumentError)
    list << "Test"
    list << :Test2
    list << ModuleObject.new(nil, :YARD)
    expect(list.size).to eq 3
  end

  it "added value should be a proxy if parameter was String or Symbol" do
    list = CodeObjectList.new(nil)
    list << "Test"
    expect(list.first.class).to eq Proxy
  end

  it "should contain a unique list of objects" do
    obj = ModuleObject.new(nil, :YARD)
    list = CodeObjectList.new(nil)

    list << P(:YARD)
    list << obj
    expect(list.size).to eq 1

    list << :Test
    list << "Test"
    expect(list.size).to eq 2
  end
end
