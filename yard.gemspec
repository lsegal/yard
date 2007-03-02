require 'rubygems'
SPEC = Gem::Specification.new do |s|
  s.name        = "yard"
  s.version     = "0.2.0"
  s.date        = "2007-03-01"
  s.author      = "Loren Segal"
  s.email       = "lsegal@soen.ca"
  s.homepage    = "http://yard.soen.ca"
  s.platform    = Gem::Platform::RUBY
  s.summary     = "A documentation tool for consistent and usable documentation in Ruby." 
  s.files       = Dir.glob("{bin,lib,test,templates}/**/*") + ['LICENSE.txt', 'README.pdf']
  s.executables = [ 'yardoc', 'yri' ]
#  s.has_rdoc    = false
end
  
  