describe File, ".relative_path" do
  it "should return the relative path between two files" do
    File.relative_path('a/b/c/d.html', 'a/b/d/q.html').should == '../d/q.html'
  end
  
  it "should return the relative path between two directories" do
    File.relative_path('a/b/c/d/', 'a/b/d/').should == '../d'
  end
  
  it "should handle non-normalized paths" do
    File.relative_path('Hello/./I/Am/Fred', 'Hello/Fred').should == '../../Fred'
    File.relative_path('A//B/C', 'Q/X').should == '../../Q/X'
  end
end