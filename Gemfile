# frozen_string_literal: true
source 'https://rubygems.org'

group :development do
  gem 'rspec'
  gem 'rake'
  gem 'rdoc'
  gem 'json'
  gem 'simplecov'
  gem 'samus'
  gem 'coveralls', :require => false
  gem 'rubocop', '0.44.1', :require => false
end

group :asciidoc do
  # Asciidoctor 2.0 drops support for Ruby < 2.3.
  gem 'asciidoctor', RUBY_VERSION < '2.3' ? '< 2' : '>= 0'
end

group :markdown do
  gem 'redcarpet', :platforms => [:ruby]
end

group :textile do
  gem 'RedCloth', :platforms => [:ruby]
end

group :server do
  gem 'rack'
end

group :i18n do
  gem 'gettext'
end
