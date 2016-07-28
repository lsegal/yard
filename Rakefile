require File.dirname(__FILE__) + '/lib/yard'
require File.dirname(__FILE__) + '/lib/yard/rubygems/specification'
require 'rbconfig'

YARD::VERSION.replace(ENV['YARD_VERSION']) if ENV['YARD_VERSION']

desc "Publish gem"
task :publish do
  ver = ENV['VERSION']

  if ver.nil? || ver.empty?
    fail "missing VERSION=x.y.z"
  elsif ver < YARD::VERSION
    fail "invalid version `#{ver}' (must be >= `#{YARD::VERSION}')"
  end

  file = "release-v#{ver}.tar.gz"
  cmd = "bundle exec samus"
  sh "#{cmd} build #{ver} && #{cmd} publish #{file} && rm #{file}"
end

desc "Builds the gem"
task :gem do
  sh "gem build yard.gemspec"
end

desc "Installs the gem"
task :install => :gem do
  sh "gem install yard-#{YARD::VERSION}.gem --no-document"
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
end

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "YARD #{YARD::VERSION} Documentation"]
end
