describe YARD::Registry do
  before { Registry.clear }
  it "should have an empty path for root" do
    Registry.root.path.should == ""
  end
  
  it "should #resolve any existing namespace" do
    o1 = ModuleObject.new(:root, :A)
    o2 = ModuleObject.new(o1, :B)
    o3 = ModuleObject.new(o2, :C)
    Registry.resolve(o1, "B::C").should == o3
    Registry.resolve(:root, "A::B::C")
  end
  
  it "should allow symbols as object type in #all" do
    ModuleObject.new(:root, :A)
    o1 = ClassObject.new(:root, :B)
    o2 = MethodObject.new(:root, :testing)
    Registry.all(:method, :class).should == [[:B, o1], [:testing, o2]]
  end
  
  it "should allow code object classes in #all" do
    o1 = ModuleObject.new(:root, :A)
    o2 = ClassObject.new(:root, :B)
    MethodObject.new(:root, :testing)
    Registry.all(CodeObjects::NamespaceObject).should == [[:A, o1], [:B, o2]]
  end
end