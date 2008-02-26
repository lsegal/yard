module YARD
  VERSION = "0.2.1"
end

['logger', 'namespace', 'source_parser'].each do |file|
  require(File.dirname(__FILE__) + '/' + file)
end
