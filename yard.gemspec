SPEC = Gem::Specification.new do |s|
  s.name          = "yard"
  s.summary       = "Documentation tool for consistent and usable documentation in Ruby." 
  s.description   = <<-eof
    YARD is a documentation generation tool for the Ruby programming language.
    It enables the user to generate consistent, usable documentation that can be
    exported to a number of formats very easily, and also supports extending for
    custom Ruby constructs such as custom class level definitions.
  eof
  s.version       = "0.2.3.5"
  s.date          = "2009-08-13"
  s.author        = "Loren Segal"
  s.email         = "lsegal@soen.ca"
  s.homepage      = "http://yard.soen.ca"
  s.platform      = Gem::Platform::RUBY
  s.files         = Dir.glob("{docs,bin,lib,spec,templates,benchmarks}/**/*") + ['LICENSE', 'README.markdown', 'Rakefile', '.yardopts']
  s.require_paths = ['lib']
  s.executables   = [ 'yardoc', 'yri', 'yard-graph' ]
  s.has_rdoc      = 'yard'
  s.rubyforge_project = 'yard'
  #s.add_dependency 'tadpole' 
end