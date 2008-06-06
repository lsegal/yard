require "logger"

module YARD
  class Logger < ::Logger
    def debug(*args)
      self.level = Logger::DEBUG if $DEBUG
      super
    end
    
    def enter_level(new_level = Logger::INFO, &block) 
      old_level, self.level = level, new_level
      yield
      self.level = old_level
    end
  end
  
  def self.logger
    @logger ||= YARD::Logger.new(STDERR)
  end
end

def log; YARD.logger end