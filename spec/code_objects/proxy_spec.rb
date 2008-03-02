require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Proxy do
  it "should return the object if it's in the namespace" 
#    pathobj = YARD::CodeObjects::Base.new
#    YARD::Registry.should_receive(:at, 'Path').and_return(pathobj)
#    proxyobj = YARD::CodeObjects::Proxy.new('Path', :root)
#    proxyobj.path.should == "Path"
end