require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Server::DocServerSerializer do
  describe '#serialized_path' do
    before do
      Registry.clear
      @serializer = Server::DocServerSerializer.new
    end

    after(:all) { Server::Adapter.shutdown }

    it "should return '/PREFIX/library/toplevel' for root" do
      expect(@serializer.serialized_path(Registry.root)).to eq "toplevel"
    end

    it "should return /PREFIX/library/Object for Object in a library" do
      expect(@serializer.serialized_path(P('A::B::C'))).to eq 'A/B/C'
    end

    it "should link to instance method as Class:method" do
      obj = CodeObjects::MethodObject.new(:root, :method)
      expect(@serializer.serialized_path(obj)).to eq 'toplevel:method'
    end

    it "should link to class method as Class.method" do
      obj = CodeObjects::MethodObject.new(:root, :method, :class)
      expect(@serializer.serialized_path(obj)).to eq 'toplevel.method'
    end

    it "should link to anchor for constant" do
      obj = CodeObjects::ConstantObject.new(:root, :FOO)
      expect(@serializer.serialized_path(obj)).to eq 'toplevel#FOO-constant'
    end

    it "should link to anchor for class variable" do
      obj = CodeObjects::ClassVariableObject.new(:root, :@@foo)
      expect(@serializer.serialized_path(obj)).to eq 'toplevel#@@foo-classvariable'
    end

    it "should link files using file/ prefix" do
      file = CodeObjects::ExtraFileObject.new('a/b/FooBar.md', '')
      expect(@serializer.serialized_path(file)).to eq 'file/FooBar'
    end

    it "should handle unicode data" do
      file = CodeObjects::ExtraFileObject.new("test\u0160", '')
      expect(@serializer.serialized_path(file)).to eq 'file/test_C5A0'
    end if defined?(::Encoding)
  end
end