SPEC = Gem::Specification.new do |s|
  s.name          = "yard"
  s.version       = "0.2.3"
  s.date          = "2009-06-07"
  s.author        = "Loren Segal"
  s.email         = "lsegal@soen.ca"
  s.homepage      = "http://yard.soen.ca"
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Documentation tool for consistent and usable documentation in Ruby." 
  s.files         = Dir.glob("{docs,bin,lib,spec,templates,benchmarks}/**/*") + ['LICENSE', 'README.markdown', 'Rakefile']
  s.require_paths = ['lib']
  s.executables   = [ 'yardoc', 'yri', 'yard-graph' ]
  s.has_rdoc      = false
  s.rubyforge_project = 'yard'
  #s.add_dependency 'tadpole' 
end