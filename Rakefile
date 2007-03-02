require 'rake/gempackagetask'
load 'yard.gemspec'

task :default => :gem

Rake::GemPackageTask.new(SPEC) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end