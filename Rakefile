require 'rubygems'
require 'rake/gempackagetask'
require 'spec'
require 'spec/rake/spectask'

SPEC = Gem::Specification.new do |s|
  s.name        = "yard"
  s.version     = "0.2.1"
  s.date        = "2007-05-20"
  s.author      = "Loren Segal"
  s.email       = "lsegal@soen.ca"
  s.homepage    = "http://yard.soen.ca"
  s.platform    = Gem::Platform::RUBY
  s.summary     = "A documentation tool for consistent and usable documentation in Ruby." 
  s.files       = Dir.glob("{bin,lib,test,templates}/**/*") + ['LICENSE.txt', 'README.txt', 'help.pdf']
  s.executables = [ 'yardoc', 'yri', 'yard-graph' ]
  s.add_dependency 'erubis' 
  s.has_rdoc    = false
end
  
task :default => :gem

Rake::GemPackageTask.new(SPEC) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :install do 
  puts(install = "sudo gem install pkg/#{SPEC.name}-#{SPEC.version}.gem --local")
  `rake gem && #{install}`
end

desc "Run all specs"
Spec::Rake::SpecTask.new("specs") do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir["spec/**/*_spec.rb"].sort
end