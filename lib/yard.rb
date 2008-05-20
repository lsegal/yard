module YARD
  VERSION = "0.2.2"
  ROOT = File.join(File.dirname(__FILE__), 'yard')
  TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'templates')

  def self.parse(paths = "**/*.rb", level = Logger::INFO)
    old_level, YARD.logger.level = YARD.logger.level, level
    
    files = Dir[File.join(Dir.pwd, paths)]
    files.each do |file|
      YARD.logger.debug("Processing #{file}")
      YARD::Parser::SourceParser.parse(file)
    end
    
    YARD.logger.level = old_level
  end
end

$:.unshift(YARD::ROOT)

['logging', 'autoload', 'symbol_hash', 'extra'].each do |file|
  require file
end

