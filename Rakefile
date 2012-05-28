require File.dirname(__FILE__) + '/lib/yard'
require File.dirname(__FILE__) + '/lib/yard/rubygems/specification'
require 'rbconfig'

YARD::VERSION.replace(ENV['YARD_VERSION']) if ENV['YARD_VERSION']

task :default => :specs

desc "Builds the gem"
task :gem do
  Gem::Builder.new(eval(File.read('yard.gemspec'))).build
end

desc "Installs the gem"
task :install => :gem do
  sh "gem install yard-#{YARD::VERSION}.gem --no-rdoc --no-ri"
end

begin
require 'rvm-tester'
RVM::Tester::TesterTask.new do |t|
  t.bundle_install = false # don't need to do this all the time
  t.verbose = true
end
rescue LoadError
end

task :travis_ci do
  status = 0
  ENV['SUITE'] = '1'
  ENV['CI'] = '1'
  system "bundle exec rake specs"
  status = 1 if $?.to_i != 0
  if RUBY_VERSION >= '1.9' && RUBY_PLATFORM != 'java'
    puts ""
    puts "Running specs with in legacy mode"
    system "bundle exec rake specs LEGACY=1"
    status = 1 if $?.to_i != 0
  end
  exit(status)
end

begin
  hide = '_spec\.rb$,spec_helper\.rb$,ruby_lex\.rb$,autoload\.rb$'
  if YARD::Parser::SourceParser.parser_type == :ruby
    hide += ',legacy\/.+_handler'
  else
    hide += ',ruby_parser\.rb$,ast_node\.rb$,handlers\/ruby\/[^\/]+\.rb$'
  end

  require 'rspec'
  require 'rspec/core/rake_task'

  desc "Run all specs"
  RSpec::Core::RakeTask.new("specs") do |t|
    $DEBUG = true if ENV['DEBUG']
    t.rspec_opts = ENV['SUITE'] ? [] : ['-c']
    t.rspec_opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
    t.rspec_opts += ['-I', YARD::ROOT]
    t.pattern = "spec/**/*_spec.rb"
    t.verbose = $DEBUG ? true : false

    if ENV['RCOV']
      t.rcov = true
      t.rcov_opts = ['-x', hide]
    end
  end
  task :spec => :specs
rescue LoadError
  begin # Try for rspec 1.x
    require 'spec'
    require 'spec/rake/spectask'

    Spec::Rake::SpecTask.new("specs") do |t|
      $DEBUG = true if ENV['DEBUG']
      t.spec_opts = ["--format", "specdoc", "--colour"]
      t.spec_opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
      t.pattern = "spec/**/*_spec.rb"

      if ENV['RCOV']
        t.rcov = true
        t.rcov_opts = ['-x', hide]
      end
    end
    task :spec => :specs
  rescue LoadError
    warn "warn: RSpec tests not available. `gem install rspec` to enable them."
  end
end

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "YARD #{YARD::VERSION} Documentation"]
end
