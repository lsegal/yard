unless defined?(Gem::DocManager.load_yardoc)
  require 'yard/rubygems/specification'
  require 'yard/rubygems/doc_manager'
end
