YARD_ROOT = File.join(File.dirname(__FILE__), 'yard')
YARD_TEMPLATE_ROOT = File.join(File.dirname(__FILE__), '..', 'templates')

$LOAD_PATH.unshift(YARD_ROOT)

['yard_logger'].each do |file|
  require File.join(YARD_ROOT, file)
end

module YARD
  VERSION = "0.2.1"
  
  module CodeObjects; end
  module Generators; end
  module Parser
    module Lexer; end
    module Ruby; end
  end
  module Handlers; end
  module Tags
    module Library; end
  end
  
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

%w[ 
  symbol_hash
  tags/*
  code_objects/base 
  code_objects/namespace_object
  code_objects/*
  parser/**/*
  handlers/base
  handlers/*
  generators/*
  serializers/*
  registry
  tag_library
].each do |file|
  file = File.join(File.dirname(__FILE__), 'yard', file + ".rb")
  Dir[file].each do |f|
    if require(f)
      YARD.logger.debug "Loading #{f}..."
    end
  end
end