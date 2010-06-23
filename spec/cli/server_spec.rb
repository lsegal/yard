require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::Server do
  before do
    @no_verify_libraries = false
    @libraries = {}
    @options = {:single_library => true, :caching => false}
    @server_options = {:Port => 8808}
    @adapter = mock(:adapter)
    @cli = YARD::CLI::Server.new
    @cli.stub!(:adapter).and_return(@adapter)
  end
  
  after(:all) do
    Templates::Template.extra_includes.delete(Server::DocServerHelper)
    Templates::Engine.template_paths.pop
  end
  
  def run(*args)
    if @libraries.empty?
      library = Server::LibraryVersion.new(File.basename(Dir.pwd), '.yardoc')
      @libraries = {library.name => [library]}
    end
    unless @no_verify_libraries
      @libraries.values.each {|libs| libs.each {|lib| File.should_receive(:exist?).at_least(1).times.with(lib.yardoc_file).and_return(true) } }
    end
    @adapter.should_receive(:new).with(@libraries, @options, @server_options).and_return(@adapter)
    @adapter.should_receive(:start)
    @cli.run(*args.flatten)
  end

  it "should default to current dir if no library is specified" do
    Dir.should_receive(:pwd).and_return('/path/to/foo')
    @libraries['foo'] = [Server::LibraryVersion.new('foo', '.yardoc')]
    run
  end
  
  it "should use .yardoc as yardoc file is library list is odd" do
    @libraries['a'] = [Server::LibraryVersion.new('a', '.yardoc')]
    run 'a'
  end
  
  it "should force multi library if more than one library is listed" do
    @options[:single_library] = false
    @libraries['a'] = [Server::LibraryVersion.new('a', 'b')]
    @libraries['c'] = [Server::LibraryVersion.new('c', '.yardoc')]
    run %w(a b c)
  end
  
  it "should accept -m, --multi-library" do
    @options[:single_library] = false
    run '-m'
    run '--multi-library'
  end
  
  it "should accept -c, --cache" do
    @options[:caching] = true
    run '-c'
    run '--cache'
  end
  
  it "should accept -r, --reload" do
    @options[:incremental] = true
    run '-r'
    run '--reload'
  end
  
  it "should accept -d, --daemon" do
    @server_options[:daemonize] = true
    run '-d'
    run '--daemon'
  end
  
  it "should accept -p, --port" do
    @server_options[:Port] = 10
    run '-p', '10'
    run '--port', '10'
  end
  
  it "should accept --docroot" do
    @server_options[:DocumentRoot] = '/foo/bar'
    run '--docroot', '/foo/bar'
  end
  
  it "should accept -a webrick to create WEBrick adapter" do
    @cli.should_receive(:adapter=).with(YARD::Server::WebrickAdapter)
    run '-a', 'webrick'
  end
  
  it "should accept -a rack to create Rack adapter" do
    @cli.should_receive(:adapter=).with(YARD::Server::RackAdapter)
    run '-a', 'rack'
  end
  
  it "should default to Rack adapter if exists on system" do
    @cli.unstub(:adapter)
    @cli.should_receive(:require).with('rubygems').and_return(false)
    @cli.should_receive(:require).with('rack').and_return(true)
    @cli.should_receive(:adapter=).with(YARD::Server::RackAdapter)
    @cli.send(:select_adapter)
  end

  it "should fall back to WEBrick adapter if Rack is not on system" do
    @cli.unstub(:adapter)
    @cli.should_receive(:require).with('rubygems').and_return(false)
    @cli.should_receive(:require).with('rack').and_raise(LoadError)
    @cli.should_receive(:adapter=).with(YARD::Server::WebrickAdapter)
    @cli.send(:select_adapter)
  end
  
  it "should accept -s, --server" do
    @server_options[:server] = 'thin'
    run '-s', 'thin'
    run '--server', 'thin'
  end
  
  it "should accept -g, --gems" do
    @no_verify_libraries = true
    @options[:single_library] = false
    @libraries['gem1'] = [Server::LibraryVersion.new('gem1', :gem, '1.0.0')]
    @libraries['gem2'] = [Server::LibraryVersion.new('gem2', :gem, '1.0.0')]
    gem1 = mock(:gem1)
    gem1.stub!(:name).and_return('gem1')
    gem1.stub!(:version).and_return('1.0.0')
    gem2 = mock(:gem2)
    gem2.stub!(:name).and_return('gem2')
    gem2.stub!(:version).and_return('1.0.0')
    source = mock(:source_index)
    source.stub!(:find_name).and_return([gem1, gem2])
    Gem.stub!(:source_index).and_return(source)
    run '-g'
    run '--gems'
  end
end