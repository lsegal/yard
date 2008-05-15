require "logger"

module YARD
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
