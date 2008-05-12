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
end