# frozen_string_literal: true
require File.expand_path('lib/yard/version', __dir__)

Gem::Specification.new do |s|
  s.name          = "yard"
  s.summary       = "Documentation tool for consistent and usable documentation in Ruby."
  s.description   = <<-EOF
    YARD is a documentation generation tool for the Ruby programming language.
    It enables the user to generate consistent, usable documentation that can be
    exported to a number of formats very easily, and also supports extending for
    custom Ruby constructs such as custom class level definitions.
  EOF
  s.version       = YARD::VERSION
  s.author        = "Loren Segal"
  s.email         = "lsegal@soen.ca"
  s.homepage      = "http://yardoc.org"
  s.platform      = Gem::Platform::RUBY
  s.files         = Dir['{lib,docs,po,templates}/**/*', '.yardopts*', 'CHANGELOG.md', 'LICENSE', 'LEGAL', 'README.md']
  s.require_paths = ['lib']
  s.executables   = ['yard', 'yardoc', 'yri']
  s.license = 'MIT' if s.respond_to?(:license=)
  s.metadata['yard.run'] = 'yri'
  s.required_ruby_version = '>= 2.0.0' if s.respond_to?(:required_ruby_version=)
end
