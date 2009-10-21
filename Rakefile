require File.dirname(__FILE__) + '/lib/yard'
require 'rubygems'
require 'rake/gempackagetask'
require 'spec'
require 'spec/rake/spectask'

WINDOWS = (PLATFORM =~ /win32|cygwin/ ? true : false) rescue false
SUDO = WINDOWS ? '' : 'sudo'

task :default => :specs

load 'yard.gemspec'
Rake::GemPackageTask.new(SPEC) do |pkg|
  pkg.gem_spec = SPEC
  pkg.need_zip = true
  pkg.need_tar = true
end

desc "Install the gem locally"
task :install => :package do 
  sh "#{SUDO} gem install pkg/#{SPEC.name}-#{SPEC.version}.gem --local --no-rdoc --no-ri"
  sh "rm -rf pkg/yard-#{SPEC.version}" unless ENV['KEEP_FILES']
end

desc "Run all specs"
Spec::Rake::SpecTask.new("specs") do |t|
  $DEBUG = true if ENV['DEBUG']
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
  t.spec_files = Dir["spec/**/*_spec.rb"].sort
  
  if ENV['RCOV']
    hide = '_spec\.rb$,spec_helper\.rb$,ruby_lex\.rb$,autoload\.rb$'
    hide += ',legacy\/.+_handler,html_syntax_highlight_helper18\.rb$' if RUBY19
    hide += ',ruby_parser\.rb$,ast_node\.rb$,handlers\/ruby\/[^\/]+\.rb$,html_syntax_highlight_helper\.rb$' if RUBY18
    t.rcov = true 
    t.rcov_opts = ['-x', hide]
  end
end
task :spec => :specs

YARD::Rake::YardocTask.new do |t|
  t.after = lambda { `cp -R docs/images/ doc/images/` }
end
