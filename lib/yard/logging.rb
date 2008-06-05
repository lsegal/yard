require "logger"

module YARD
  def self.logger
    unless @logger
      @logger = Logger.new(STDERR)
      @logger.level = Logger::INFO
    end
    class << @logger
      def debug(*args)
        self.level = Logger::DEBUG if $DEBUG
        super
      end
    end
    @logger
  end
end

class Logger::Formatter
  def call(sev, time, prog, msg)
    "[#{sev.downcase}]: #{msg}\n"
  end
end

def log; YARD.logger end
