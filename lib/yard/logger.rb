module Logger
  def self.method_missing(meth, message = "", prefix = true)
    prefix = prefix ? "[#{meth.to_s.upcase}]: " : ""
    STDOUT.puts "#{prefix}#{message}"
  end
end

def log; Logger end
