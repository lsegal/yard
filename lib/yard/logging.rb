require 'logger'

module YARD
  class Logger < ::Logger
    def self.instance(pipe = STDERR)
      @logger ||= new(pipe)
    end
    
    def initialize(*args)
      super
      self.level = INFO
      self.formatter = method(:format_log)
    end
    
    def debug(*args)
      self.level = DEBUG if $DEBUG
      super
    end
    
    def enter_level(new_level = level, &block) 
      old_level, self.level = level, new_level
      yield
      self.level = old_level
    end
    
    def format_log(sev, time, prog, msg)
      "[#{sev.downcase}]: #{msg}\n"
    end
  end
end

def log; YARD::Logger.instance end