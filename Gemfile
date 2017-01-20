# frozen_string_literal: true
source 'https://rubygems.org'

group :development do
  gem 'rspec', '~> 3.5'
  gem 'rake', '~> 11.0'
  gem 'rdoc', '~> 4.0'
  gem 'json'
  gem 'simplecov'
  gem 'samus'
  gem 'coveralls', :require => false
  gem 'rubocop', '0.44.1', :require => false
end

group :asciidoc do
  gem 'asciidoctor'
end

group :markdown do
  gem 'redcarpet', '~> 3.0', :platforms => :mri
  gem 'kramdown', :platforms => :jruby
end

group :textile do
  gem 'RedCloth', :platforms => :ruby
end

group :server do
  gem 'rack', '~> 2.0'
end

group :i18n do
  gem 'gettext', '>= 2.2.1'
end
