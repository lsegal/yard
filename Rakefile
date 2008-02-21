require 'rake/gempackagetask'
load 'yard.gemspec'

task :default => :gem

Rake::GemPackageTask.new(SPEC) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :install do 
  install = "sudo gem install pkg/#{SPEC.name}-#{SPEC.version}.gem --local"
  `rake gem && #{install}`
  puts install
end