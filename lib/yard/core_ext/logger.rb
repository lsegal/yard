class Logger::Formatter
  def call(sev, time, prog, msg)
    "[#{sev.downcase}]: #{msg}\n"
  end
end
