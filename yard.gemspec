require File.expand_path(File.dirname(__FILE__) + '/lib/yard')
SPEC = Gem::Specification.new do |s|
  s.name          = "yard"
  s.summary       = "Documentation tool for consistent and usable documentation in Ruby." 
  s.description   = <<-eof
    YARD is a documentation generation tool for the Ruby programming language.
    It enables the user to generate consistent, usable documentation that can be
    exported to a number of formats very easily, and also supports extending for
    custom Ruby constructs such as custom class level definitions.
  eof
  s.version       = YARD::VERSION
  s.date          = "2010-06-22"
  s.author        = "Loren Segal"
  s.email         = "lsegal@soen.ca"
  s.homepage      = "http://yardoc.org"
  s.platform      = Gem::Platform::RUBY
  s.files         = Dir.glob("{docs,bin,lib,spec,templates,benchmarks}/**/*") + ['ChangeLog', 'LICENSE', 'LEGAL', 'README.md', 'Rakefile', '.yardopts']
  s.require_paths = ['lib']
  s.executables   = ['yard', 'yardoc', 'yri']
  s.has_rdoc      = 'yard'
  s.rubyforge_project = 'yard'
end