# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'coveralls_reborn', :require => false if RUBY_VERSION >= '2.7.0'
  gem 'json'
  gem 'rake'
  gem 'rdoc', RUBY_VERSION < '2.7.0' ? '~> 6.0' : nil
  gem 'rspec'
  gem 'simplecov' if RUBY_VERSION >= '2.7.0'
  gem 'webrick'
end

group :asciidoc do
  gem 'asciidoctor'
  gem 'logger' if RUBY_VERSION >= '2.3.0'
end

group :markdown do
  gem 'commonmarker'
  gem 'redcarpet'
end

group :textile do
  gem 'RedCloth'
end

group :server do
  gem 'rack', '~> 2.0' if RUBY_VERSION < '2.6.0'
  gem 'rackup' if RUBY_VERSION >= '2.6.0'
end

group :i18n do
  gem 'gettext'
end
