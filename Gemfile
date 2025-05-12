# frozen_string_literal: true
source 'https://rubygems.org'

group :development do
  gem 'coveralls_reborn', :require => false
  gem 'json'
  gem 'rake'
  gem 'rdoc', '= 6.1.2.1'
  gem 'rspec', '>= 3.11.0'
  gem 'samus', '~> 3.0.9', :require => false
  gem 'simplecov'
  gem 'webrick'
end

group :lint do
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rake'
end

group :asciidoc do
  gem 'asciidoctor'
  gem 'logger' # needed for asciidoctor
end

group :markdown do
  gem 'commonmarker', '~> 0.x'
  gem 'redcarpet'
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
