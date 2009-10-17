require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Templates::Template do
  def template(path)
    YARD::Templates::Engine.template!(path, '/full/path/' + path.to_s)
  end
  
  describe '.full_paths' do
    it "should list full_path" do
      mod = template(:a)
      mod.full_paths.should == [Pathname.new('/full/path/a')]
    end
    
    it "should list paths of included modules" do
      mod = template(:a)
      mod.send(:include, template(:b))
      mod.full_paths.should == [Pathname.new('/full/path/a'), Pathname.new('/full/path/b')]
    end
    
    it "should list paths from modules of included modules" do
      mod = template(:c)
      mod.send(:include, template(:d))
      mod.send(:include, template(:a))
      mod.full_paths.should == ['c', 'a', 'b', 'd'].map {|o| Pathname.new('/full/path/' + o) }
    end
    
    it "should only list full paths of modules that respond to full_paths" do
      mod = template(:d)
      mod.send(:include, Enumerable)
      mod.full_paths.should == [Pathname.new('/full/path/d')]
    end
  end
  
  describe '.load_setup_rb' do
    it "should load setup.rb file for module" do
      File.should_receive(:file?).with('/full/path/e/setup.rb').and_return(true)
      File.should_receive(:read).with('/full/path/e/setup.rb').and_return('def success; end')
      template(:e).new.should respond_to(:success)
    end
  end
  
  describe '.T' do
    it "should load template from relative path" do
      mod = template(:a)
      Engine.should_receive(:template).with(mod, '../other')
      mod.T('../other')
    end
  end
  
  describe '.find_file' do
    it "should find file in module's full_path" do
      FileTest.should_receive(:file?).with('/full/path/a/basename').and_return(false)
      FileTest.should_receive(:file?).with('/full/path/b/basename').and_return(true)
      template(:a).find_file('basename').should == Pathname.new('/full/path/b/basename')
    end
    
    it "should return nil if no file is found" do
      FileTest.should_receive(:file?).with('/full/path/a/basename').and_return(false)
      FileTest.should_receive(:file?).with('/full/path/b/basename').and_return(false)
      template(:a).find_file('basename').should be_nil
    end
  end
  
  describe '#file' do
    it "should read the file if it exists" do
      FileTest.should_receive(:file?).with('/full/path/e/abc').and_return(true)
      IO.should_receive(:read).with('/full/path/e/abc').and_return('hello world')
      template(:e).new.file('abc').should == 'hello world'
    end
    
    it "should raise ArgumentError if the file does not exist" do
      FileTest.should_receive(:file?).with('/full/path/e/abc').and_return(false)
      lambda { template(:e).new.file('abc') }.should raise_error(ArgumentError)
    end
  end
end