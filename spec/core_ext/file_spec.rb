require File.dirname(__FILE__) + '/../spec_helper'

describe File do
  describe ".relative_path" do
    it "should return the relative path between two files" do
      File.relative_path('a/b/c/d.html', 'a/b/d/q.html').should == '../d/q.html'
    end
  
    it "should return the relative path between two directories" do
      File.relative_path('a/b/c/d/', 'a/b/d/').should == '../d'
    end
  
    it "should return only the to file if from file is in the same directory as the to file" do
      File.relative_path('a/b/c/d', 'a/b/c/e').should == 'e'
    end
  
    it "should handle non-normalized paths" do
      File.relative_path('Hello/./I/Am/Fred', 'Hello/Fred').should == '../../Fred'
      File.relative_path('A//B/C', 'Q/X').should == '../../Q/X'
    end
  end
  
  describe '.cleanpath' do
    it "should clean double brackets" do
      File.cleanpath('A//B/C').should == "A/B/C"
    end
    
    it "should clean a path with ." do
      File.cleanpath('Hello/./I/.Am/Fred').should == "Hello/I/.Am/Fred"
    end

    it "should clean a path with .." do
      File.cleanpath('Hello/../World').should == "World"
    end

    it "should clean a path with multiple .." do
      File.cleanpath('A/B/C/../../D').should == "A/D"
    end

    it "should clean a path ending in .." do
      File.cleanpath('A/B/C/D/..').should == "A/B/C"
    end
    
    it "should not pass the initial directory" do
      File.cleanpath('C/../../D').should == "../D"
    end
  end
end