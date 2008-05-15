require "logger"

module YARD
  def self.logger
    unless @logger
      @logger = Logger.new(STDOUT)
      @logger.datetime_format = ""
    end
    @logger
  end
end
