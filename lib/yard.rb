module YARD
  VERSION = "0.2.2"
  ROOT = File.join(File.dirname(__FILE__), 'yard')
  TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'templates')
  
  def self.parse(*args) Parser::SourceParser.parse(*args) end
end

$:.unshift(YARD::ROOT)

files  = ['logging', 'autoload']
files += Dir.glob File.join(YARD::ROOT, 'core_ext/*')
files.each {|file| require file.gsub(/\.rb$/, '') }


