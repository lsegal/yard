require "logger"

module YARD
  def self.logger
    unless @logger
      @logger = Logger.new(STDOUT)
      @logger.datetime_format = ""
      @logger.level = Logger::INFO
    end
    @logger
  end
end

def log; YARD.logger end