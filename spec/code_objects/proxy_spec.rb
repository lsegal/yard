require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Proxy do
  before { Registry.clear }
  
  it "should return the object if it's in the registry" do
    pathobj = CodeObjects::NamespaceObject.new(nil, :YARD, :module, nil, nil)
    Registry.should_receive(:at).at_least(:once).with("YARD").and_return(pathobj)
    proxyobj = P(:root, :YARD)
    proxyobj.path.should == :YARD
    proxyobj.type.should == :module
  end
end