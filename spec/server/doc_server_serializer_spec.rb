require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Server::DocServerSerializer do
  describe '#serialized_path' do
    before do
      Registry.clear
      @command = mock(:command)
      @command.stub!(:single_project).and_return(false)
      @command.stub!(:project).and_return('foo')
      @serializer = Server::DocServerSerializer.new(@command)
    end
    
    it "should return '/docs/project/toplevel' for root" do
      @serializer.serialized_path(Registry.root).should == "/docs/foo/toplevel"
    end
    
    it "should return /docs/project/Object for Object in a project" do
      @serializer.serialized_path(P('A::B::C')).should == '/docs/foo/A/B/C'
    end
    
    it "should link to instance method as Class:method" do
      obj = CodeObjects::MethodObject.new(:root, :method)
      @serializer.serialized_path(obj).should == '/docs/foo/toplevel:method'
    end

    it "should link to class method as Class.method" do
      obj = CodeObjects::MethodObject.new(:root, :method, :class)
      @serializer.serialized_path(obj).should == '/docs/foo/toplevel.method'
    end
    
    it "should not link to /project/ if single_project = true" do
      @command.stub!(:single_project).and_return(true)
      @serializer.serialized_path(Registry.root).should == "/docs/toplevel"
    end
  end
end