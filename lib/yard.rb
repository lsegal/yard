module YARD
  VERSION = "0.2.3.5"
  ROOT = File.dirname(__FILE__)
  TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'templates')
  
  def self.parse(*args) Parser::SourceParser.parse(*args) end
  def self.parse_string(*args) Parser::SourceParser.parse_string(*args) end
  
  # Loads gems that match the name 'yard-*' (recommended) or 'yard_*'.
  # This is called immediately after YARD is loaded to allow plugin support.
  # 
  # @return [true] always returns true
  def self.load_plugins
    Gem.source_index.entries.each do |pkgname, gem|
      begin
        if gem.name =~ /^yard[-_]/
          log.debug "Loading plugin '#{gem.name}'..."
          require gem.name 
        end
      rescue Gem::LoadError, LoadError
        log.warn "Error loading plugin '#{gem.name}'"
      end
    end
    true
  end
end

# Ruby 1.9.2 removes '.' which is not exactly a good idea
$LOAD_PATH.push('.') if RUBY_VERSION >= '1.9.2'

# Keep track of Ruby version for compatibility code
RUBY19, RUBY18 = *(RUBY_VERSION >= "1.9" ? [true, false] : [false, true])

# Load Ruby core extension classes
Dir.glob(File.join(YARD::ROOT, 'yard', 'core_ext', '*')).each do |file|
  require file.gsub(/\.rb$/, '')
end

['autoload', 'globals'].each do |file| 
  require File.join(YARD::ROOT, 'yard', file)
end

# Load any plugins
begin
  require 'rubygems'
  YARD.load_plugins
rescue LoadError
  log.debug "RubyGems is not present, skipping plugin loading"
end
