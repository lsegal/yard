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
end