SPEC = Gem::Specification.new do |s|
  s.name          = "yard"
  s.version       = "0.2.3"
  s.date          = "2008-05-16"
  s.author        = "Loren Segal"
  s.email         = "lsegal, soen.ca"
  s.homepage      = "http://yard.soen.ca"
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Documentation tool for consistent and usable documentation in Ruby." 
  s.files         = Dir.glob("{bin,lib,spec,templates,benchmarks}/**/*") + ['LICENSE', 'docs/FAQ.markdown', 'README.markdown', 'Rakefile']
  s.require_paths = ['lib']
  s.executables   = [ 'yardoc', 'yri', 'yard-graph' ]
  s.has_rdoc      = false
  s.rubyforge_project = 'yard'
  #s.add_dependency 'tadpole' 
end