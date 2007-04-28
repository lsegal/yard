class Logger
  class << self
    attr_accessor :notices, :warnings, :errors
    @notices, @warnings, @errors = true, true, true
    
    def notice
      puts "Notice: #{msg}"
    end
    
    def warning(msg)
      puts "Warning: #{msg}"
    end
    
    def error(msg)
      puts "Error: #{msg}"
    end
  end
end
    