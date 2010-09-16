module YARD
  class Config
    class << self
      # The configuration options
      # @return [SymbolHash]
      attr_accessor :options
    end

    # The location where YARD stores user-specific settings
    CONFIG_DIR = File.expand_path('~/.yard')
    
    # The main configuration YAML file.
    CONFIG_FILE = File.join(CONFIG_DIR, 'config')
    
    # File listing all ignored plugins 
    # @deprecated Set `ignored_plugins` in the {CONFIG_FILE} instead.
    IGNORED_PLUGINS = File.join(CONFIG_DIR, 'ignored_plugins')
    
    # Default configuration options
    DEFAULT_CONFIG_OPTIONS = {
      :load_plugins => false,   # Whether to load plugins automatically with YARD
      :ignored_plugins => [],   # A list of ignored plugins by name
      :autoload_plugins => []   # A list of plugins to be automatically loaded
    }
    
    YARD_PLUGIN_PREFIX = /^yard[-_]/
    
    # Loads settings from {CONFIG_FILE}
    # @return [void]
    def self.load
      self.options = SymbolHash.new(false)
      options.update(DEFAULT_CONFIG_OPTIONS)
      options.update(read_config_file)
      add_ignored_plugins_file
      translate_plugin_names
      load_plugins
    end
    
    # Loads gems that match the name 'yard-*' (recommended) or 'yard_*' except
    # those listed in +~/.yard/ignored_plugins+. This is called immediately 
    # after YARD is loaded to allow plugin support.
    # 
    # @return [true] always returns true
    def self.load_plugins
      load_gem_plugins &&
        load_autoload_plugins &&
        load_commandline_plugins ? true : false
    end
    
    def self.load_plugin(name)
      name = translate_plugin_name(name)
      return false if options[:ignored_plugins].include?(name)
      return false if name =~ /^yard-doc-/
      log.debug "Loading plugin '#{name}'..."
      require name
      true
    rescue LoadError => e
      load_plugin_failed(name, e)
    end
    
    private
    
    # Load gem plugins if :load_plugins is true
    def self.load_gem_plugins
      return true unless options[:load_plugins]
      require 'rubygems'
      result = true
      Gem.source_index.find_name('').each do |gem|
        begin
          next true unless gem.name =~ YARD_PLUGIN_PREFIX
          load_plugin(gem.name)
        rescue Gem::LoadError => e
          tmp = load_plugin_failed(gem.name, e)
          result = tmp if !tmp
        end
      end
      result
    rescue LoadError
      log.debug "RubyGems is not present, skipping plugin loading"
      false
    end
    
    # Load plugins set in :autoload_plugins
    def self.load_autoload_plugins
      options[:autoload_plugins].each {|name| load_plugin(name) }
    end
    
    def self.load_commandline_plugins
      arguments.each_with_index do |arg, i|
        next unless arg == '--plugin'
        load_plugin(arguments[i+1])
      end
    end
    
    def self.load_plugin_failed(name, exception)
      log.warn "Error loading plugin '#{name}'"
      log.backtrace(exception)
      false
    end
    
    # Legacy support for {IGNORED_PLUGINS}
    def self.add_ignored_plugins_file
      if File.file?(IGNORED_PLUGINS)
        options[:ignored_plugins] += File.read(IGNORED_PLUGINS).split(/\s+/)
      end
    end
    
    def self.translate_plugin_names
      options[:ignored_plugins].map! {|name| translate_plugin_name(name) }
      options[:autoload_plugins].map! {|name| translate_plugin_name(name) }
    end

    def self.read_config_file
      if File.file?(CONFIG_FILE)
        require 'yaml'
        YAML.load_file(CONFIG_FILE)
      else
        {}
      end
    end
    
    def self.translate_plugin_name(name)
      name = name.gsub('/', '') # Security sanitization
      name = "yard-" + name unless name =~ YARD_PLUGIN_PREFIX
      name
    end
    
    def self.arguments; ARGV end
  end
  
  Config.options = Config::DEFAULT_CONFIG_OPTIONS
end
