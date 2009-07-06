module YARD
  VERSION = "0.2.3"
  ROOT = File.dirname(__FILE__)
  TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'templates')
  
  def self.parse(*args) Parser::SourceParser.parse(*args) end
  def self.parse_string(*args) Parser::SourceParser.parse_string(*args) end
end

# Keep track of Ruby version for compatibility code
RUBY19, RUBY18 = *(RUBY_VERSION >= "1.9" ? [true, false] : [false, true])

$:.unshift(YARD::ROOT)

files  = ['yard/logging', 'yard/autoload']
files += Dir.glob File.join(YARD::ROOT, 'yard/core_ext/*')
files.each {|file| require file.gsub(/\.rb$/, '') }
