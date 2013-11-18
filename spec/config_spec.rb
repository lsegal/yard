require File.join(File.dirname(__FILE__), "spec_helper")

require 'yaml'

describe YARD::Config do
  describe '.load' do
    before do
      expect(File).to receive(:file?).twice.with(CLI::Yardoc::DEFAULT_YARDOPTS_FILE).and_return(false)
    end

    it "should use default options if no ~/.yard/config is found" do
      expect(File).to receive(:file?).with(YARD::Config::IGNORED_PLUGINS).and_return(false)
      expect(File).to receive(:file?).with(YARD::Config::CONFIG_FILE).and_return(false)
      YARD::Config.load
      expect(YARD::Config.options).to eq YARD::Config::DEFAULT_CONFIG_OPTIONS
    end

    it "should overwrite options with data in ~/.yard/config" do
      expect(File).to receive(:file?).with(YARD::Config::CONFIG_FILE).and_return(true)
      expect(File).to receive(:file?).with(YARD::Config::IGNORED_PLUGINS).and_return(false)
      expect(YAML).to receive(:load_file).with(YARD::Config::CONFIG_FILE).and_return({'test' => true})
      YARD::Config.load
      expect(YARD::Config.options[:test]).to be_true
    end

    it "should ignore any plugins specified in '~/.yard/ignored_plugins'" do
      expect(File).to receive(:file?).with(YARD::Config::CONFIG_FILE).and_return(false)
      expect(File).to receive(:file?).with(YARD::Config::IGNORED_PLUGINS).and_return(true)
      expect(File).to receive(:read).with(YARD::Config::IGNORED_PLUGINS).and_return('yard-plugin plugin2')
      YARD::Config.load
      expect(YARD::Config.options[:ignored_plugins]).to eq ['yard-plugin', 'yard-plugin2']
      expect(YARD::Config).to_not receive(:require).with('yard-plugin2')
      expect(YARD::Config.load_plugin('yard-plugin2')).to eq false
    end

    it "should load safe_mode setting from --safe command line option" do
      expect(File).to receive(:file?).with(YARD::Config::IGNORED_PLUGINS).and_return(false)
      expect(File).to receive(:file?).with(YARD::Config::CONFIG_FILE).and_return(false)
      ARGV.replace(['--safe'])
      YARD::Config.load
      expect(YARD::Config.options[:safe_mode]).to be_true
      ARGV.replace([''])
    end
  end

  describe '.save' do
    it "should save options to config file" do
      YARD::Config.stub!(:options).and_return(:a => 1, :b => %w(a b c))
      file = mock(:file)
      expect(File).to receive(:open).with(YARD::Config::CONFIG_FILE, 'w').and_yield(file)
      expect(file).to receive(:write).with(YAML.dump(:a => 1, :b => %w(a b c)))
      YARD::Config.save
    end
  end

  describe '.load_plugin' do
    it "should load a plugin by 'name' as 'yard-name'" do
      expect(YARD::Config).to receive(:require).with('yard-foo')
      expect(log).to receive(:debug).with(/Loading plugin 'yard-foo'/).once
      expect(YARD::Config.load_plugin('foo')).to eq true
    end

    it "should not load plugins like 'doc-*'" do
      expect(YARD::Config).to_not receive(:require).with('yard-doc-core')
      YARD::Config.load_plugin('doc-core')
      YARD::Config.load_plugin('yard-doc-core')
    end

    it "should load plugin by 'yard-name' as 'yard-name'" do
      expect(YARD::Config).to receive(:require).with('yard-foo')
      expect(log).to receive(:debug).with(/Loading plugin 'yard-foo'/).once
      expect(YARD::Config.load_plugin('yard-foo')).to eq true
    end

    it "should load plugin by 'yard_name' as 'yard_name'" do
      expect(YARD::Config).to receive(:require).with('yard_foo')
      expect(log).to receive(:debug).with(/Loading plugin 'yard_foo'/).once
      log.show_backtraces = false
      expect(YARD::Config.load_plugin('yard_foo')).to eq true
    end

    it "should log error if plugin is not found" do
      expect(YARD::Config).to receive(:require).with('yard-foo').and_raise(LoadError)
      expect(log).to receive(:warn).with(/Error loading plugin 'yard-foo'/).once
      expect(YARD::Config.load_plugin('yard-foo')).to eq false
    end

    it "should sanitize plugin name (remove /'s)" do
      expect(YARD::Config).to receive(:require).with('yard-foofoo')
      expect(YARD::Config.load_plugin('foo/foo')).to eq true
    end

    it "should ignore plugins in :ignore_plugins" do
      YARD::Config.stub!(:options).and_return(:ignored_plugins => ['yard-foo', 'yard-bar'])
      expect(YARD::Config.load_plugin('foo')).to eq false
      expect(YARD::Config.load_plugin('bar')).to eq false
    end
  end

  describe '.load_plugins' do
    it "should load gem plugins if :load_plugins is true" do
      YARD::Config.stub!(:options).and_return(:load_plugins => true, :ignored_plugins => [], :autoload_plugins => [])
      YARD::Config.stub!(:load_plugin)
      expect(YARD::Config).to receive(:require).with('rubygems')
      YARD::Config.load_plugins
    end

    it "should ignore gem loading if RubyGems cannot load" do
      YARD::Config.stub!(:options).and_return(:load_plugins => true, :ignored_plugins => [], :autoload_plugins => [])
      expect(YARD::Config).to receive(:require).with('rubygems').and_raise(LoadError)
      expect(YARD::Config.load_plugins).to eq false
    end

    it "should load certain plugins automatically when specified in :autoload_plugins" do
      expect(File).to receive(:file?).with(CLI::Yardoc::DEFAULT_YARDOPTS_FILE).and_return(false)
      YARD::Config.stub!(:options).and_return(:load_plugins => false, :ignored_plugins => [], :autoload_plugins => ['yard-plugin'])
      expect(YARD::Config).to receive(:require).with('yard-plugin').and_return(true)
      expect(YARD::Config.load_plugins).to eq true
    end

    it "should parse --plugin from command line arguments" do
      expect(YARD::Config).to receive(:arguments).at_least(1).times.and_return(%w(--plugin foo --plugin bar a b c))
      expect(YARD::Config).to receive(:load_plugin).with('foo').and_return(true)
      expect(YARD::Config).to receive(:load_plugin).with('bar').and_return(true)
      expect(YARD::Config.load_plugins).to eq true
    end

    it "should load --plugin arguments from .yardopts" do
      expect(File).to receive(:file?).with(CLI::Yardoc::DEFAULT_YARDOPTS_FILE).twice.and_return(true)
      expect(File).to receive(:file?).with(YARD::Config::CONFIG_FILE).and_return(false)
      expect(File).to receive(:file?).with(YARD::Config::IGNORED_PLUGINS).and_return(false)
      expect(File).to receive(:read_binary).with(CLI::Yardoc::DEFAULT_YARDOPTS_FILE).twice.and_return('--plugin foo')
      expect(YARD::Config).to receive(:load_plugin).with('foo')
      YARD::Config.load
    end

    it "should load any gem plugins starting with 'yard_' or 'yard-'" do
      expect(File).to receive(:file?).with(CLI::Yardoc::DEFAULT_YARDOPTS_FILE).and_return(false)
      YARD::Config.stub!(:options).and_return(:load_plugins => true, :ignored_plugins => ['yard_plugin'], :autoload_plugins => [])
      plugins = {
        'yard' => mock('yard'),
        'yard_plugin' => mock('yard_plugin'),
        'yard-plugin' => mock('yard-plugin'),
        'my-yard-plugin' => mock('yard-plugin'),
        'rspec' => mock('rspec'),
      }
      plugins.each do |k, v|
        expect(v).to receive(:name).at_least(1).times.and_return(k)
      end

      source_mock = mock(:source_index)
      expect(source_mock).to receive(:find_name).with('').and_return(plugins.values)
      expect(Gem).to receive(:source_index).and_return(source_mock)
      expect(YARD::Config).to receive(:load_plugin).with('yard_plugin').and_return(false)
      expect(YARD::Config).to receive(:load_plugin).with('yard-plugin').and_return(true)
      expect(YARD::Config.load_plugins).to eq true
    end

    it "should log an error if a gem raises an error" do
      YARD::Config.stub!(:options).and_return(:load_plugins => true, :ignored_plugins => [], :autoload_plugins => [])
      plugins = {
        'yard-plugin' => mock('yard-plugin')
      }
      plugins.each do |k, v|
        expect(v).to receive(:name).at_least(1).times.and_return(k)
      end

      source_mock = mock(:source_index)
      expect(source_mock).to receive(:find_name).with('').and_return(plugins.values)
      expect(Gem).to receive(:source_index).and_return(source_mock)
      expect(YARD::Config).to receive(:load_plugin).with('yard-plugin').and_raise(Gem::LoadError)
      expect(log).to receive(:warn).with(/Error loading plugin 'yard-plugin'/)
      expect(YARD::Config.load_plugins).to eq false
    end
  end
end
