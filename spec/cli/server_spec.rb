require File.dirname(__FILE__) + '/../spec_helper'

class Server::WebrickAdapter; def start; end end

describe YARD::CLI::Server do
  before do
    @no_verify_libraries = false
    @no_adapter_mock = false
    @libraries = {}
    @options = {:single_library => true, :caching => false}
    @server_options = {:Port => 8808}
    @adapter = mock(:adapter)
    @adapter.stub!(:setup)
    new_cli

    # Checking if a file/dir exists will return false unless a matching stub is setup to return true
    File.stub!(:exist?).and_return(false)
    File.stub!(:exists?).and_return(false)
    Dir.stub!(:exist?).and_return(false)
    Dir.stub!(:exists?).and_return(false)
  end

  def new_cli
    @cli = YARD::CLI::Server.new
    @cli.stub!(:generate_doc_for_first_time)
  end

  def rack_required
    begin; require 'rack'; rescue LoadError; pending "rack required for this test" end
  end

  def bundler_required
    begin; require 'bundler'; rescue LoadError; pending "bundler required for this test" end
  end

  def unstub_adapter
    @no_adapter_mock = true
  end

  def run(*args)
    if @libraries.empty?
      library = Server::LibraryVersion.new(File.basename(Dir.pwd), nil, File.expand_path('.yardoc'))
      @libraries = {library.name => [library]}
    end
    unless @no_verify_libraries
      @libraries.values.each {|libs| libs.each {|lib| mock_dir lib.yardoc_file }}
    end
    unless @no_adapter_mock
      @cli.stub!(:adapter).and_return(@adapter)
      @adapter.should_receive(:new).with(@libraries, @options, @server_options).and_return(@adapter)
      @adapter.should_receive(:start)
    end

    @cli.run(*args.flatten)
    assert_libraries @libraries, @cli.libraries

    new_cli
  end

  def assert_libraries(expected_libs, actual_libs)
    actual_libs.should == expected_libs
    expected_libs.each { |name, libs|
      libs.each_with_index { |expected,i|
        actual = actual_libs[name][i]
        [:source, :source_path, :yardoc_file].each {|m|
          actual.send(m).should == expected.send(m)
        }
      }
    }
  end

  # Mocks the existance of a dir.
  def mock_dir(dir)
    File.stub!(:exist?).with(dir).and_return(true)
    File.stub!(:exists?).with(dir).and_return(true)
    Dir.stub!(:exist?).with(dir).and_return(true)
    Dir.stub!(:exists?).with(dir).and_return(true)
    dir_e = File.expand_path(dir)
    mock_dir(dir_e) unless dir_e == dir
  end

  # Mocks the existance of a file.
  def mock_file(filename, content=nil)
    File.stub!(:exist?).with(filename).and_return(true)
    File.stub!(:exists?).with(filename).and_return(true)
    if content
      #File.stub!(:read).with(filename).and_return(content)
      File.stub!(:read_binary).with(filename).and_return(content)
    end
    filename_e = File.expand_path(filename)
    mock_file(filename_e) unless filename_e == filename
  end

  describe 'when .yardopts file exists' do
    before :each do
      Dir.stub!(:pwd).and_return('/path/to/stuff')
      @name= 'stuff'
    end

    it "should use .yardoc as the yardoc db if .yardopts doesn't specify an alternate path" do
      mock_file '/path/to/stuff/.yardopts', '--protected'
      @libraries[@name] = [Server::LibraryVersion.new(@name, nil, '/path/to/stuff/.yardoc')]
      @libraries.values[0][0].source_path = '/path/to/stuff'
      run
    end

    it "should use the yardoc db location specified by .yardopts" do
      mock_file '/path/to/stuff/.yardopts', '--db hehe'
      mock_dir 'hehe'
      @libraries[@name] = [Server::LibraryVersion.new(@name, nil, '/path/to/stuff/hehe')]
      @libraries.values[0][0].source_path = '/path/to/stuff'
      run
    end

    it "should parse .yardopts when the library list is odd" do
      mock_file '/path/to/stuff/.yardopts', '--db hehe'
      mock_dir 'hehe'
      @libraries['a'] = [Server::LibraryVersion.new('a', nil, '/path/to/stuff/hehe')]
      @libraries.values[0][0].source_path = '/path/to/stuff'
      run 'a'
    end
  end

  describe "when .yardopts file doesn't exist" do
    before :each do
      File.should_receive(:exists?).at_least(:once).with(/^(.*[\\\/])?\.yardopts$/).and_return(false)
    end

    it "should default to .yardoc if no library is specified" do
      Dir.should_receive(:pwd).at_least(:once).and_return('/path/to/foo')
      @libraries['foo'] = [Server::LibraryVersion.new('foo', nil, '/path/to/foo/.yardoc')]
      run
    end

    it "should use .yardoc as yardoc file if library list is odd" do
      @libraries['a'] = [Server::LibraryVersion.new('a', nil, File.expand_path('.yardoc'))]
      run 'a'
    end

    it "should force multi library if more than one library is listed" do
      mock_dir 'b'
      mock_dir '.yardoc'
      @options[:single_library] = false
      @libraries['a'] = [Server::LibraryVersion.new('a', nil, File.expand_path('b'))]
      @libraries['c'] = [Server::LibraryVersion.new('c', nil, File.expand_path('.yardoc'))]
      run %w(a b c)
    end
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
    @server_options[:DocumentRoot] = Dir.pwd + '/__foo/bar'
    run '--docroot', '__foo/bar'
  end

  it "should accept -a webrick to create WEBrick adapter" do
    @cli.should_receive(:adapter=).with(YARD::Server::WebrickAdapter)
    run '-a', 'webrick'
  end

  it "should accept -a rack to create Rack adapter" do
    rack_required
    @cli.should_receive(:adapter=).with(YARD::Server::RackAdapter)
    run '-a', 'rack'
  end

  it "should default to Rack adapter if exists on system" do
    rack_required
    @cli.should_receive(:require).with('rubygems').and_return(false)
    @cli.should_receive(:require).with('rack').and_return(true)
    @cli.should_receive(:adapter=).with(YARD::Server::RackAdapter)
    @cli.send(:select_adapter)
  end

  it "should fall back to WEBrick adapter if Rack is not on system" do
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
    @libraries['gem1'] = [Server::LibraryVersion.new('gem1', '1.0.0', nil, :gem)]
    @libraries['gem2'] = [Server::LibraryVersion.new('gem2', '1.0.0', nil, :gem)]
    gem1 = mock(:gem1)
    gem1.stub!(:name).and_return('gem1')
    gem1.stub!(:version).and_return('1.0.0')
    gem1.stub!(:full_gem_path).and_return('/path/to/foo')
    gem2 = mock(:gem2)
    gem2.stub!(:name).and_return('gem2')
    gem2.stub!(:version).and_return('1.0.0')
    gem2.stub!(:full_gem_path).and_return('/path/to/bar')
    specs = {'gem1' => gem1, 'gem2' => gem2}
    source = mock(:source_index)
    source.stub!(:find_name).and_return do |k, ver|
      k == '' ? specs.values : specs.grep(k).map {|name| specs[name] }
    end
    Gem.stub!(:source_index).and_return(source)
    run '-g'
    run '--gems'
  end

  it "should accept -G, --gemfile" do
    bundler_required
    @no_verify_libraries = true
    @options[:single_library] = false

    @libraries['gem1'] = [Server::LibraryVersion.new('gem1', '1.0.0', nil, :gem)]
    @libraries['gem2'] = [Server::LibraryVersion.new('gem2', '1.0.0', nil, :gem)]
    gem1 = mock(:gem1)
    gem1.stub!(:name).and_return('gem1')
    gem1.stub!(:version).and_return('1.0.0')
    gem1.stub!(:full_gem_path).and_return('/path/to/foo')
    gem2 = mock(:gem2)
    gem2.stub!(:name).and_return('gem2')
    gem2.stub!(:version).and_return('1.0.0')
    gem2.stub!(:full_gem_path).and_return('/path/to/bar')
    specs = {'gem1' => gem1, 'gem2' => gem2}
    lockfile_parser = mock(:new)
    lockfile_parser.stub!(:specs).and_return([gem1, gem2])
    Bundler::LockfileParser.stub!(:new).and_return(lockfile_parser)

    File.should_receive(:exists?).at_least(2).times.with("Gemfile.lock").and_return(true)
    File.stub!(:read)

    run '-G'
    run '--gemfile'

    File.should_receive(:exists?).with("different_name.lock").and_return(true)
    run '--gemfile', 'different_name'
  end

  it "should warn if lockfile is not found (with -G)" do
    bundler_required
    File.should_receive(:exists?).with(/\.yardopts$/).at_least(:once).and_return(false)
    File.should_receive(:exists?).with('somefile.lock').and_return(false)
    log.should_receive(:warn).with(/Cannot find somefile.lock/)
    run '-G', 'somefile'
  end

  it "should error if Bundler not available (with -G)" do
    @cli.should_receive(:require).with('bundler').and_raise(LoadError)
    log.should_receive(:error).with(/Bundler not available/)
    run '-G'
  end

  it "should load template paths after adapter template paths" do
    unstub_adapter
    @cli.adapter = Server::WebrickAdapter
    run '-t', 'foo'
    Templates::Engine.template_paths.last.should == 'foo'
  end

  it "should load ruby code (-e) after adapter" do
    unstub_adapter
    @cli.adapter = Server::WebrickAdapter
    path = File.dirname(__FILE__) + '/tmp.adapterscript.rb'
    begin
      File.open(path, 'w') do |f|
        f.puts "YARD::Templates::Engine.register_template_path 'foo'"
        f.flush
        run '-e', f.path
        Templates::Engine.template_paths.last.should == 'foo'
      end
    ensure
      File.unlink(path)
    end
  end
end
