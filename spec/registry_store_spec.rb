require File.join(File.dirname(__FILE__), "spec_helper")

describe YARD::RegistryStore do
  describe '#load' do
    it "should load old yardoc format if .yardoc is a file" do
      File.should_receive(:directory?).with('foo').and_return(false)
      File.should_receive(:file?).with('foo').and_return(true)
      File.should_receive(:read).with('foo').and_return('FOO')
      Marshal.should_receive(:load).with('FOO')

      RegistryStore.new.load('foo')
    end
    
    it "should load new yardoc format if .yardoc is a directory" do
      File.should_receive(:directory?).with('foo').and_return(true)
      File.should_receive(:file?).with('foo/checksums').and_return(false)
      File.should_receive(:file?).with('foo/proxy_types').and_return(false)
      File.should_receive(:file?).with('foo/objects/root.dat').and_return(false)

      RegistryStore.new.load('foo').should == true
    end
    
    it "should return true if .yardoc is loaded (file)" do
      File.should_receive(:directory?).with('myyardoc').and_return(false)
      File.should_receive(:file?).with('myyardoc').and_return(true)
      File.should_receive(:read).with('myyardoc').and_return(Marshal.dump(''))
      RegistryStore.new.load('myyardoc').should == true
    end

    it "should return true if .yardoc is loaded (directory)" do
      File.should_receive(:directory?).with('foo').and_return(true)
      File.should_receive(:file?).with('foo/checksums').and_return(false)
      File.should_receive(:file?).with('foo/proxy_types').and_return(false)
      File.should_receive(:file?).with('foo/objects/root.dat').and_return(false)
      RegistryStore.new.load('foo').should == true
    end

    it "should return false if .yardoc does not exist" do
      RegistryStore.new.load('NONEXIST').should == false
    end
    
    it "should return false if there is no file to load" do
      RegistryStore.new.load(nil).should == false
    end
  end
  
  describe '#put' do
    it "should assign values" do
      store = RegistryStore.new
      store.put(:YARD, true)
      store.get(:YARD).should == true
    end
  end
  
  describe '#get' do
    it "should hit cache if object exists" do
      store = RegistryStore.new
      store.put(:YARD, true)
      store.get(:YARD).should == true
    end
    
    it "should hit backstore on cache miss and cache is not fully loaded" do
      serializer = mock(:serializer)
      serializer.should_receive(:deserialize).with(:YARD)
      store = RegistryStore.new
      store.load('foo')
      store.instance_variable_set("@available_objects", 100)
      store.instance_variable_set("@serializer", serializer)
      store.get(:YARD)
    end
  end
end