require 'optparse'

module YARD
  module CLI
    class Base
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