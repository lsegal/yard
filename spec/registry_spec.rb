describe YARD::Registry do
  it "should have an empty path" do
    Registry.root.path.should == ""
  end
end