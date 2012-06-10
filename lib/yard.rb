module YARD
  VERSION = "0.8.2.1"

  # The root path for YARD source libraries
  ROOT = File.expand_path(File.dirname(__FILE__))

  # The root path for YARD builtin templates
  TEMPLATE_ROOT = File.join(ROOT, '..', 'templates')

  # @deprecated Use {Config::CONFIG_DIR}
  CONFIG_DIR = File.expand_path('~/.yard')

  # An alias to {Parser::SourceParser}'s parsing method
  #
  # @example Parse a glob of files
  #   YARD.parse('lib/**/*.rb')
  # @see Parser::SourceParser.parse
  def self.parse(*args) Parser::SourceParser.parse(*args) end

  # An alias to {Parser::SourceParser}'s parsing method
  #
  # @example Parse a string of input
  #   YARD.parse_string('class Foo; end')
  # @see Parser::SourceParser.parse_string
  def self.parse_string(*args) Parser::SourceParser.parse_string(*args) end

  # (see YARD::Config.load_plugins)
  # @deprecated Use {Config.load_plugins}
  def self.load_plugins; YARD::Config.load_plugins end
end

# Keep track of Ruby version for compatibility code
RUBY19, RUBY18 = *(RUBY_VERSION >= "1.9.1" ? [true, false] : [false, true])

# Load Ruby core extension classes
Dir.glob(File.join(YARD::ROOT, 'yard', 'core_ext', '*.rb')).each do |file|
  require file
end

# Backport RubyGems SourceIndex and other classes
require File.join(YARD::ROOT, 'yard', 'rubygems', 'backports')

['autoload', 'globals'].each do |file|
  require File.join(YARD::ROOT, 'yard', file)
end

# Load YARD configuration options (and plugins)
YARD::Config.load
