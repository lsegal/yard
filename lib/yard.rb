module YARD
  VERSION = "0.2.2"
  ROOT = File.join(File.dirname(__FILE__), 'yard')
  TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'templates')
end

$:.unshift(YARD::ROOT)

['logging', 'symbol_hash', 'autoload'].each do |file|
  require file
end

