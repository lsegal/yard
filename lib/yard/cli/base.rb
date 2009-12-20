require 'optparse'

module YARD
  module CLI
    # Abstract base class for CLI utilities. Provides some helper methods for
    # the option parser
    # 
    # @abstract
    class Base
      def initialize
        log.show_backtraces = false
      end
      
      # Adds a set of common options to the tail of the OptionParser
      # 
      # @param [OptionParser] opts the option parser object
      # @return [void]
      def common_options(opts)
        opts.separator ""
        opts.separator "Other options:"
        opts.on_tail('-q', '--quiet', 'Show no warnings.') { log.level = Logger::ERROR }
        opts.on_tail('--verbose', 'Show more information.') { log.level = Logger::INFO }
        opts.on_tail('--debug', 'Show debugging information.') { log.level = Logger::DEBUG }
        opts.on_tail('--backtrace', 'Show stack traces') { log.show_backtraces = true }
        opts.on_tail('-v', '--version', 'Show version.') { puts "yard #{YARD::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help.')  { puts opts; exit }
      end
    end
  end
end