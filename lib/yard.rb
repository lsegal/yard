$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'yard')

require 'logger'

module YARD
  VERSION = "0.2.1"
  
  module CodeObjects; end
  module Generators; end
  module Parser
    module Lexer; end
    module Ruby; end
  end
  module Handlers; end
  module TagLibrary; end
end

#['logger', 'namespace', 'source_parser'].each do |file|
#  require(File.dirname(__FILE__) + '/' + file)
#end

Dir[File.dirname(__FILE__) + "/yard/**/*.rb"].each do |file|
  log.debug "Loading #{file}..."
  require file                                        
end