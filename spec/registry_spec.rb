describe YARD::Registry do
  it "should have an empty path for root" do
    Registry.root.path.should == ""
  end
end