# frozen_string_literal: true
source 'https://rubygems.org'

group :development do
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.0.0')
    gem 'irb'
  end
  gem 'rspec', '>= 3.11.0'
  gem 'rake'
  gem 'rdoc', '= 6.1.2.1'
  gem 'json'
  gem 'simplecov'
  gem 'samus', '~> 3.0.9', :require => false
  gem 'coveralls_reborn', :require => false
  gem 'webrick'
end

group :asciidoc do
  gem 'asciidoctor'
end

group :markdown do
  gem 'redcarpet'
  gem 'commonmarker'
end

group :textile do
  gem 'RedCloth'
end

group :server do
  gem 'rack', '~> 2.0'
end

group :i18n do
  gem 'gettext'
end
