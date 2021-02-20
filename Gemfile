# frozen_string_literal: true
source 'https://rubygems.org'

group :development do
  gem 'rspec'
  gem 'rake'
  gem 'rdoc'
  gem 'json'
  gem 'simplecov'
  gem 'samus', '~> 3.0.9', :require => false
  if RUBY_VERSION < '2.4'
    gem 'coveralls', :require => false
  else
    gem 'coveralls_reborn', '~> 0.20.0', require: false
  end
  gem 'webrick'
end

group :asciidoc do
  gem 'asciidoctor'
end

group :markdown do
  gem 'redcarpet'
end

group :textile do
  gem 'RedCloth'
end

group :server do
  gem 'rack'
end

group :i18n do
  gem 'gettext'
end
