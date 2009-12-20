require 'logger'

module YARD
  # Handles console logging for info, warnings and errors.
  # Uses the stdlib Logger class in Ruby for all the backend logic.
  class Logger < ::Logger
    attr_accessor :show_backtraces
    
    # The logger instance
    # @return [Logger] the logger instance
    def self.instance(pipe = STDERR)
      @logger ||= new(pipe)
    end
    
    # Creates a new logger
    def initialize(*args)
      super
      self.show_backtraces = true
      self.level = WARN
      self.formatter = method(:format_log)
    end
    
    # Changes the debug level to DEBUG if $DEBUG is set
    # and writes a debugging message.
    def debug(*args)
      self.level = DEBUG if $DEBUG
      super
    end
    
    def backtrace(exc)
      return unless show_backtraces
      error "#{exc.class.class_name}: #{exc.message}"
      error "Stack trace:" + 
        exc.backtrace[0..5].map {|x| "\n\t#{x}" }.join + "\n"
    end
    
    # Sets the logger level for the duration of the block
    # 
    # @example
    #   log.enter_level(Logger::ERROR) do
    #     YARD.parse_string "def x; end"
    #   end
    # @param [Fixnum] new_level the logger level for the duration of the block.
    #   values can be found in Ruby's Logger class.
    # @yield the block with the logger temporarily set to +new_level+
    def enter_level(new_level = level, &block) 
      old_level, self.level = level, new_level
      yield
      self.level = old_level
    end
    
    # Log format (from Logger implementation)
    def format_log(sev, time, prog, msg)
      "[#{sev.downcase}]: #{msg}\n"
    end
  end
end
