require File.join(File.dirname(__FILE__), "spec_helper")

describe YARD::RegistryStore do
  before do
    FileUtils.rm_rf("foo")
    @store = RegistryStore.new
    @serializer = Serializers::YardocSerializer.new('foo')
    @foo = CodeObjects::MethodObject.new(nil, :foo)
    @bar = CodeObjects::ClassObject.new(nil, :Bar)
    Serializers::YardocSerializer.stub!(:new).and_return(@serializer)
  end

  describe '#load' do
    it "should load root.dat as full object list if it is a Hash" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(@serializer).to receive(:deserialize).with('root').and_return({:root => @foo, :A => @bar})
      expect(@store.load('foo')).to eq true
      expect(@store.root).to eq @foo
      expect(@store.get('A')).to eq @bar
    end

    it "should load old yardoc format if .yardoc is a file" do
      expect(File).to receive(:directory?).with('foo').and_return(false)
      expect(File).to receive(:file?).with('foo').and_return(true)
      expect(File).to receive(:read_binary).with('foo').and_return('FOO')
      expect(Marshal).to receive(:load).with('FOO')

      @store.load('foo')
    end

    it "should load new yardoc format if .yardoc is a directory" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(File).to receive(:file?).with('foo/objects/root.dat').and_return(false)

      expect(@store.load('foo')).to eq true
    end

    it "should return true if .yardoc is loaded (file)" do
      expect(File).to receive(:directory?).with('myyardoc').and_return(false)
      expect(File).to receive(:file?).with('myyardoc').and_return(true)
      expect(File).to receive(:read_binary).with('myyardoc').and_return(Marshal.dump(''))
      expect(@store.load('myyardoc')).to eq true
    end

    it "should return true if .yardoc is loaded (directory)" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(File).to receive(:file?).with('foo/objects/root.dat').and_return(false)
      expect(@store.load('foo')).to eq true
    end

    it "should return false if .yardoc does not exist" do
      expect(@store.load('NONEXIST')).to eq false
    end

    it "should return false if there is no file to load" do
      expect(@store.load(nil)).to eq false
    end

    it "should load checksums if they exist" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(true)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/objects/root.dat').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(File).to receive(:readlines).with('foo/checksums').and_return([
        'file1 CHECKSUM1', '  file2 CHECKSUM2 '
      ])
      expect(@store.load('foo')).to eq true
      expect(@store.checksums).to eq ({ 'file1' => 'CHECKSUM1', 'file2' => 'CHECKSUM2'} )
    end

    it "should load proxy_types if they exist" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(true)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(File).to receive(:file?).with('foo/objects/root.dat').and_return(false)
      expect(File).to receive(:read_binary).with('foo/proxy_types').and_return(Marshal.dump({'a' => 'b'}))
      expect(@store.load('foo')).to eq true
      expect(@store.proxy_types).to eq ({ 'a' => 'b'} )
    end

    it "should load root object if it exists" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(File).to receive(:file?).with('foo/objects/root.dat').and_return(true)
      expect(File).to receive(:read_binary).with('foo/objects/root.dat').and_return(Marshal.dump(@foo))
      expect(@store.load('foo')).to eq true
      expect(@store.root).to eq @foo
    end
  end

  describe '#save' do
    before do
      @store.stub!(:write_proxy_types)
      @store.stub!(:write_checksums)
      @store.stub!(:destroy)
    end

    after do
      Registry.single_object_db = nil
    end

    def saves_to_singledb
      expect(@serializer).to receive(:serialize).once.with(instance_of(Hash))
      @store.save(true, 'foo')
    end

    def add_items(n)
      n.times {|i| @store[i.to_s] = @foo }
    end

    def saves_to_multidb
      times = @store.keys.size
      expect(@serializer).to receive(:serialize).exactly(times).times
      @store.save(true, 'foo')
      @last = times
    end

    it "should save as single object db if single_object_db is nil and there are less than 3000 objects" do
      Registry.single_object_db = nil
      add_items(100)
      saves_to_singledb
    end

    it "should save as single object db if single_object_db is nil and there are more than 3000 objects" do
      Registry.single_object_db = nil
      add_items(5000)
      saves_to_singledb
    end

    it "should save as single object db if single_object_db is true (and any amount of objects)" do
      Registry.single_object_db = true
      add_items(100)
      saves_to_singledb
      add_items(5000)
      saves_to_singledb
    end

    it "should never save as single object db if single_object_db is false" do
      Registry.single_object_db = false
      add_items(100)
      saves_to_multidb
      add_items(5000)
      saves_to_multidb
    end
  end

  describe '#put' do
    it "should assign values" do
      @store.put(:YARD, @foo)
      expect(@store.get(:YARD)).to eq @foo
    end

    it "should treat '' as root" do
      @store.put('', @foo)
      expect(@store.get(:root)).to eq @foo
    end
  end

  describe '#get' do
    it "should hit cache if object exists" do
      @store.put(:YARD, @foo)
      expect(@store.get(:YARD)).to eq @foo
    end

    it "should hit backstore on cache miss and cache is not fully loaded" do
      serializer = mock(:serializer)
      expect(serializer).to receive(:deserialize).once.with(:YARD).and_return(@foo)
      @store.load('foo')
      @store.instance_variable_set("@loaded_objects", 0)
      @store.instance_variable_set("@available_objects", 100)
      @store.instance_variable_set("@serializer", serializer)
      expect(@store.get(:YARD)).to eq @foo
      expect(@store.get(:YARD)).to eq @foo
      expect(@store.instance_variable_get("@loaded_objects")).to eq 1
    end
  end

  [:keys, :values].each do |item|
    describe "##{item}" do
      it "should load entire database if reload=true" do
        expect(File).to receive(:directory?).with('foo').and_return(true)
        @store.load('foo')
        expect(@store).to receive(:load_all)
        @store.send(item, true)
      end

      it "should not load entire database if reload=false" do
        expect(File).to receive(:directory?).with('foo').and_return(true)
        @store.load('foo')
        expect(@store).to_not receive(:load_all)
        @store.send(item, false)
      end
    end
  end

  describe '#paths_for_type' do
    after { Registry.clear }

    it "should set all object types if not set by object_types" do
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(@serializer).to receive(:deserialize).with('root').and_return({:'A#foo' => @foo, :A => @bar})
      @store.load('foo')
      expect(@store.paths_for_type(:method)).to eq ['#foo']
      expect(@store.paths_for_type(:class)).to eq ['Bar']
    end

    it "should keep track of types when assigning values" do
      @store.put(:abc, @foo)
      expect(@store.paths_for_type(@foo.type)).to eq ['abc']
    end

    it "should reassign path if type changes" do
      foo = CodeObjects::ClassObject.new(:root, :Foo)
      @store.put('Foo', foo)
      expect(@store.get('Foo').type).to eq :class
      expect(@store.paths_for_type(:class)).to eq ["Foo"]
      foo = CodeObjects::ModuleObject.new(:root, :Foo)
      @store.put('Foo', foo)
      expect(@store.get('Foo').type).to eq :module
      expect(@store.paths_for_type(:class)).to eq []
      expect(@store.paths_for_type(:module)).to eq ["Foo"]
    end
  end

  describe '#values_for_type' do
    it "should return all objects with type" do
      @store.put(:abc, @foo)
      expect(@store.values_for_type(@foo.type)).to eq [@foo]
    end
  end

  describe '#load_all' do
    it "should load the entire database" do
      foomock = mock(:Foo)
      barmock = mock(:Bar)
      foomock.stub!(:type).and_return(:class)
      barmock.stub!(:type).and_return(:class)
      expect(foomock).to receive(:path).and_return('Foo')
      expect(barmock).to receive(:path).and_return('Bar')
      expect(File).to receive(:directory?).with('foo').and_return(true)
      expect(File).to receive(:file?).with('foo/proxy_types').and_return(false)
      expect(File).to receive(:file?).with('foo/object_types').and_return(false)
      expect(File).to receive(:file?).with('foo/checksums').and_return(false)
      expect(File).to receive(:file?).with('foo/objects/root.dat').and_return(false)
      expect(@store).to receive(:all_disk_objects).at_least(1).times.and_return(['foo/objects/foo', 'foo/objects/bar'])
      @store.load('foo')
      serializer = @store.instance_variable_get("@serializer")
      expect(serializer).to receive(:deserialize).with('foo/objects/foo', true).and_return(foomock)
      expect(serializer).to receive(:deserialize).with('foo/objects/bar', true).and_return(barmock)
      @store.send(:load_all)
      expect(@store.instance_variable_get("@available_objects")).to eq 2
      expect(@store.instance_variable_get("@loaded_objects")).to eq 2
      expect(@store[:Foo]).to eq foomock
      expect(@store[:Bar]).to eq barmock
    end
  end

  describe '#destroy' do
    it "should destroy file ending in .yardoc when force=false" do
      expect(File).to receive(:file?).with('foo.yardoc').and_return(true)
      expect(File).to receive(:unlink).with('foo.yardoc')
      @store.instance_variable_set("@file", 'foo.yardoc')
      expect(@store.destroy).to eq true
    end

    it "should destroy dir ending in .yardoc when force=false" do
      expect(File).to receive(:directory?).with('foo.yardoc').and_return(true)
      expect(FileUtils).to receive(:rm_rf).with('foo.yardoc')
      @store.instance_variable_set("@file", 'foo.yardoc')
      expect(@store.destroy).to eq true
    end

    it "should not destroy file/dir not ending in .yardoc when force=false" do
      expect(File).to_not receive(:file?).with('foo')
      expect(File).to_not receive(:directory?).with('foo')
      expect(File).to_not receive(:unlink).with('foo')
      expect(FileUtils).to_not receive(:rm_rf).with('foo')
      @store.instance_variable_set("@file", 'foo')
      expect(@store.destroy).to eq false
    end

    it "should destroy any file/dir when force=true" do
      expect(File).to receive(:file?).with('foo').and_return(true)
      expect(File).to receive(:unlink).with('foo')
      @store.instance_variable_set("@file", 'foo')
      expect(@store.destroy(true)).to eq true
    end
  end

  describe '#locale' do
    it "should load ./po/LOCALE_NAME.po" do
      fr_locale = I18n::Locale.new("fr")
      expect(I18n::Locale).to receive(:new).with("fr").and_return(fr_locale)
      expect(Registry).to receive(:po_dir).and_return("po")
      expect(fr_locale).to receive(:load).with("po")
      expect(@store.locale("fr")).to eq fr_locale
    end
  end
end
