class Logger
  class << self
    attr_accessor :notices, :warnings, :errors
    @notices, @warnings, @errors = true, true, true
    
    def notice
      STDERR.puts "Notice: #{msg}"
    end
    
    def warning(msg)
      STDERR.puts "Warning: #{msg}"
    end
    
    def error(msg)
      STDERR.puts "Error: #{msg}"
    end
  end
end
    