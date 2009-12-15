require File.join(File.dirname(__FILE__), "spec_helper")
include CodeObjects

describe YARD::Registry do
  before { Registry.clear }
  
  describe '.yardoc_file_for_gem' do
    before do
      @gem = mock('gem')
      @gem.stub!(:name).and_return('foo')
      @gem.stub!(:full_name).and_return('foo-1.0')
      @gem.stub!(:full_gem_path).and_return('/path/to/foo')
    end
    
    it "should return nil if gem isn't found" do
      Gem.source_index.should_receive(:find_name).with('foo', '>= 0').and_return([])
      Registry.yardoc_file_for_gem('foo').should == nil
    end
    
    it "should allow version to be specified" do
      Gem.source_index.should_receive(:find_name).with('foo', '= 2').and_return([])
      Registry.yardoc_file_for_gem('foo', '= 2').should == nil
    end
    
    it "should return existing .yardoc path for gem when for_writing=false" do
      File.should_receive(:exist?).and_return(false)
      File.should_receive(:exist?).with('/path/to/foo/.yardoc').and_return(true)
      Gem.source_index.should_receive(:find_name).with('foo', '>= 0').and_return([@gem])
      Registry.yardoc_file_for_gem('foo').should == '/path/to/foo/.yardoc'
    end
    
    it "should return nil if no .yardoc path exists in gem when for_writing=false" do
      File.should_receive(:exist?).and_return(false)
      File.should_receive(:exist?).with('/path/to/foo/.yardoc').and_return(false)
      Gem.source_index.should_receive(:find_name).with('foo', '>= 0').and_return([@gem])
      Registry.yardoc_file_for_gem('foo').should == nil
    end
    
    it "should search local gem path first if for_writing=false" do
      File.should_receive(:exist?).and_return(true)
      Gem.source_index.should_receive(:find_name).with('foo', '>= 0').and_return([@gem])
      Registry.yardoc_file_for_gem('foo').should =~ %r{/.yard/gem_index/foo-1.0.yardoc$}
    end
    
    it "should return global .yardoc path for gem if for_writing=true and dir is writable" do
      File.should_receive(:writable?).with(@gem.full_gem_path).and_return(true)
      Gem.source_index.should_receive(:find_name).with('foo', '>= 0').and_return([@gem])
      Registry.yardoc_file_for_gem('foo', '>= 0', true).should == '/path/to/foo/.yardoc'
    end

    it "should return local .yardoc path for gem if for_writing=true and dir is not writable" do
      File.should_receive(:writable?).with(@gem.full_gem_path).and_return(false)
      Gem.source_index.should_receive(:find_name).with('foo', '>= 0').and_return([@gem])
      Registry.yardoc_file_for_gem('foo', '>= 0', true).should =~ %r{/.yard/gem_index/foo-1.0.yardoc$}
    end
    
    it "should return gem path if gem starts with yard-doc- and for_writing=false" do
      @gem.stub!(:name).and_return('yard-doc-core')
      @gem.stub!(:full_name).and_return('yard-doc-core-1.0')
      @gem.stub!(:full_gem_path).and_return('/path/to/yard-doc-core')
      Gem.source_index.should_receive(:find_name).with('yard-doc-core', '>= 0').and_return([@gem])
      File.should_receive(:exist?).with('/path/to/yard-doc-core/.yardoc').and_return(true)
      Registry.yardoc_file_for_gem('yard-doc-core').should == '/path/to/yard-doc-core/.yardoc'
    end
    
    it "should return nil if gem starts with yard-doc- and for_writing=true" do
      @gem.stub!(:name).and_return('yard-doc-core')
      @gem.stub!(:full_name).and_return('yard-doc-core-1.0')
      @gem.stub!(:full_gem_path).and_return('/path/to/yard-doc-core')
      Gem.source_index.should_receive(:find_name).with('yard-doc-core', '>= 0').and_return([@gem])
      File.should_receive(:exist?).with('/path/to/yard-doc-core/.yardoc').and_return(true)
      Registry.yardoc_file_for_gem('yard-doc-core', '>= 0', true).should == nil
    end
  end
  
  describe '#root' do
    it "should have an empty path for root" do
      Registry.root.path.should == ""
    end
  end
  
  describe '#resolve' do
    it "should resolve any existing namespace" do
      o1 = ModuleObject.new(:root, :A)
      o2 = ModuleObject.new(o1, :B)
      o3 = ModuleObject.new(o2, :C)
      Registry.resolve(o1, "B::C").should == o3
      Registry.resolve(:root, "A::B::C")
    end
  
    it "should resolve an object in the root namespace when prefixed with ::" do
      o1 = ModuleObject.new(:root, :A)
      o2 = ModuleObject.new(o1, :B)
      o3 = ModuleObject.new(o2, :C)
      Registry.resolve(o3, "::A").should == o1
    
      Registry.resolve(o3, "::String", false, true).should == P(:String)
    end
  
    it "should resolve instance methods with # prefix" do
      o1 = ModuleObject.new(:root, :A)
      o2 = ModuleObject.new(o1, :B)
      o3 = ModuleObject.new(o2, :C)
      o4 = MethodObject.new(o3, :methname)
      Registry.resolve(o1, "B::C#methname").should == o4
      Registry.resolve(o2, "C#methname").should == o4
      Registry.resolve(o3, "#methname").should == o4
    end
  
    it "should resolve instance methods in the root without # prefix" do
      o = MethodObject.new(:root, :methname)
      Registry.resolve(:root, 'methname').should == o
    end
  
    it "should resolve superclass methods when inheritance = true" do
      superyard = ClassObject.new(:root, :SuperYard)
      yard = ClassObject.new(:root, :YARD)
      yard.superclass = superyard
      imeth = MethodObject.new(superyard, :hello)
      cmeth = MethodObject.new(superyard, :class_hello, :class)

      Registry.resolve(yard, "#hello", false).should be_nil
      Registry.resolve(yard, "#hello", true).should == imeth
      Registry.resolve(yard, "class_hello", false).should be_nil
      Registry.resolve(yard, "class_hello", true).should == cmeth
    end

    it "should resolve mixin methods when inheritance = true" do
      yard = ClassObject.new(:root, :YARD)
      mixin = ModuleObject.new(:root, :Mixin)
      yard.mixins(:instance) << mixin
      imeth = MethodObject.new(mixin, :hello)
      cmeth = MethodObject.new(mixin, :class_hello, :class)

      Registry.resolve(yard, "#hello", false).should be_nil
      Registry.resolve(yard, "#hello", true).should == imeth
      Registry.resolve(yard, "class_hello", false).should be_nil
      Registry.resolve(yard, "class_hello", true).should == cmeth
    end
  end
  
  describe '#all' do
    it "should return objects of types specified by arguments" do
      ModuleObject.new(:root, :A)
      o1 = ClassObject.new(:root, :B)
      o2 = MethodObject.new(:root, :testing)
      r = Registry.all(:method, :class)
      r.should include(o1, o2)
    end
  
    it "should return code objects" do
      o1 = ModuleObject.new(:root, :A)
      o2 = ClassObject.new(:root, :B)
      MethodObject.new(:root, :testing)
      r = Registry.all(CodeObjects::NamespaceObject)
      r.should include(o1, o2)
    end
  
    it "should allow #all to omit list" do
      o1 = ModuleObject.new(:root, :A)
      o2 = ClassObject.new(:root, :B)
      r = Registry.all
      r.should include(o1, o2)
    end
  end
  
  describe '#paths' do
    it "should return all object paths" do
      o1 = ModuleObject.new(:root, :A)
      o2 = ClassObject.new(:root, :B)
      Registry.paths.should include('A', 'B')
    end
  end
  
  describe '#load_yardoc' do
    before do
      @store = RegistryStore.new
      RegistryStore.should_receive(:new).and_return(@store)
    end
    
    it "should delegate load to RegistryStore" do
      @store.should_receive(:load).with('foo')
      Registry.yardoc_file = 'foo'
      Registry.load_yardoc
    end
  end
end
