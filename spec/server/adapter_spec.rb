require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Server::Adapter do
  before(:all) do
    lib = Server::LibraryVersion.new('yard', '.yardoc')
    @libraries = {lib.name => [lib]}
  end
  
  after(:all) { Server::Adapter.shutdown }
  
  describe '#mount_library_commands' do
    it "should mount all library commands" do
      adapter = Server::Adapter.allocate
      Server::Adapter::PROJECT_COMMANDS.each do |path, command|
        path = path.gsub(/:library/, 'yard')
        adapter.should_receive(:mount_command) do |p, c, o| 
          p.should == path; c.should == command
        end
      end
      adapter.send(:mount_library_commands, @libraries, {})
    end
    
    it "should mount library commands for more than one library version" do
      lib1 = Server::LibraryVersion.new('yard', '1.0', '.yardoc')
      lib2 = Server::LibraryVersion.new('yard', '1.1', '.yardoc2')
      @libraries = {lib1.name => [lib1, lib2]}
      
      adapter = Server::Adapter.allocate
      [lib1, lib2].each do |lib|
        Server::Adapter::PROJECT_COMMANDS.each do |path, command|
          path = path.gsub('/:library', '/' + lib.to_s)
          adapter.should_receive(:mount_command) do |p, c, o| 
            p.should == path; c.should == command
          end
        end
      end
      adapter.send(:mount_library_commands, @libraries, {})
    end
    
    it "should not include library name if :single_library = true" do
      adapter = Server::Adapter.allocate
      Server::Adapter::PROJECT_COMMANDS.each do |path, command|
        path = path.gsub('/:library', '')
        adapter.should_receive(:mount_command) do |p, c, o| 
          p.should == path; c.should == command
        end
      end
      adapter.send(:mount_library_commands, @libraries, {:single_library => true})
    end
  end
  
  describe '#mount_root_commands' do
    it "should mount all root commands" do
      adapter = Server::Adapter.allocate
      Server::Adapter::ROOT_COMMANDS.each do |path, command|
        path = path.gsub(/:library/, 'yard')
        adapter.should_receive(:mount_command) do |p, c| 
          p.should == path; c.should == command
        end
      end
      adapter.should_receive(:mount_command)
      adapter.send(:mount_root_commands, @libraries, {})
    end
  end
  
  describe '#mount_command' do
    it "should raise NotImplementedError" do
      lambda { Server::Adapter.allocate.mount_command('', nil, nil) }.should raise_error(NotImplementedError)
    end
  end
  
  describe '#mount_servlet' do
    it "should raise NotImplementedError" do
      lambda { Server::Adapter.allocate.mount_servlet('', nil) }.should raise_error(NotImplementedError)
    end
  end
  
end