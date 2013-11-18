require File.dirname(__FILE__) + '/../spec_helper'

describe File do
  describe ".relative_path" do
    it "should return the relative path between two files" do
      expect(File.relative_path('a/b/c/d.html', 'a/b/d/q.html')).to eq '../d/q.html'
    end

    it "should return the relative path between two directories" do
      expect(File.relative_path('a/b/c/d/', 'a/b/d/')).to eq '../d'
    end

    it "should return only the to file if from file is in the same directory as the to file" do
      expect(File.relative_path('a/b/c/d', 'a/b/c/e')).to eq 'e'
    end

    it "should handle non-normalized paths" do
      expect(File.relative_path('Hello/./I/Am/Fred', 'Hello/Fred')).to eq '../../Fred'
      expect(File.relative_path('A//B/C', 'Q/X')).to eq '../../Q/X'
    end
  end

  describe '.cleanpath' do
    it "should clean double brackets" do
      expect(File.cleanpath('A//B/C')).to eq "A/B/C"
    end

    it "should clean a path with ." do
      expect(File.cleanpath('Hello/./I/.Am/Fred')).to eq "Hello/I/.Am/Fred"
    end

    it "should clean a path with .." do
      expect(File.cleanpath('Hello/../World')).to eq "World"
    end

    it "should clean a path with multiple .." do
      expect(File.cleanpath('A/B/C/../../D')).to eq "A/D"
    end

    it "should clean a path ending in .." do
      expect(File.cleanpath('A/B/C/D/..')).to eq "A/B/C"
    end

    it "should pass the initial directory" do
      expect(File.cleanpath('C/../../D')).to eq "../D"
    end

    it "should not remove multiple '../' at the beginning" do
      expect(File.cleanpath('../../A/B')).to eq '../../A/B'
    end
  end

  describe '.open!' do
    it "should create the path before opening" do
      expect(File).to receive(:directory?).with('/path/to').and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with('/path/to')
      expect(File).to receive(:open).with('/path/to/file', 'w')
      File.open!('/path/to/file', 'w')
    end

    it "should just open the file if the path exists" do
      expect(File).to receive(:directory?).with('/path/to').and_return(true)
      expect(FileUtils).to_not receive(:mkdir_p)
      expect(File).to receive(:open).with('/path/to/file', 'w')
      File.open!('/path/to/file', 'w')
    end
  end
end