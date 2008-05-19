require File.join(File.dirname(__FILE__), "spec_helper")

require 'stringio'

describe YARD::Serializers::FileSystemSerializer do
  it "should default the base path to the current directory" do
    obj = Serializers::FileSystemSerializer.new
    obj.basepath.should == '.'
  end
  
  it "should default the file extension to .html" do
    obj = Serializers::FileSystemSerializer.new
    obj.extension.should == "html"
  end
  
  it "should serialize to the correct path" do
    yard = CodeObjects::ClassObject.new(nil, :FooBar)
    meth = CodeObjects::MethodObject.new(yard, :baz)
    
    { './foo_bar/baz.html' => meth,
      './foo_bar.html' => yard }.each do |path, obj|
      io = StringIO.new
      FileUtils.stub!(:mkdir_p)
      File.should_receive(:open).with(path, 'w').and_yield(io)
      io.should_receive(:write).with("data")
    
      s = Serializers::FileSystemSerializer.new
      s.serialize(obj, "data")
    end
  end
  
  it "should guarantee the directory exists" do
    o1 = CodeObjects::ClassObject.new(nil, :Really)
    o2 = CodeObjects::ClassObject.new(o1, :Long)
    o3 = CodeObjects::ClassObject.new(o2, :PathName)
    obj = CodeObjects::MethodObject.new(o3, :foo)

    File.stub!(:open)
    FileUtils.should_receive(:mkdir_p).once.with('./really/long/path_name')
    
    s = Serializers::FileSystemSerializer.new
    s.serialize(obj, "data")
  end
end