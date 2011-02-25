require File.dirname(__FILE__) + '/lib/yard'
require 'rbconfig'

YARD::VERSION.replace(ENV['YARD_VERSION']) if ENV['YARD_VERSION']
WINDOWS = (Config::CONFIG['host_os'] =~ /mingw|win32|cygwin/ ? true : false) rescue false
SUDO = WINDOWS ? '' : 'sudo'

task :default => :specs

desc "Builds the gem"
task :gem do
  Gem.load_plugins # load plugins because they are not autoloaded anymore
  load 'yard.gemspec'
  Gem::Builder.new(SPEC).build
end

desc "Installs the gem"
task :install => :gem do 
  sh "#{SUDO} gem install yard-#{YARD::VERSION}.gem --no-rdoc --no-ri"
end

begin
  hide = '_spec\.rb$,spec_helper\.rb$,ruby_lex\.rb$,autoload\.rb$'
  hide += ',legacy\/.+_handler,html_syntax_highlight_helper18\.rb$' if RUBY19
  hide += ',ruby_parser\.rb$,ast_node\.rb$,handlers\/ruby\/[^\/]+\.rb$,html_syntax_highlight_helper\.rb$' if RUBY18

  require 'rspec'
  require 'rspec/core/rake_task'

  desc "Run all specs"
  RSpec::Core::RakeTask.new("specs") do |t|
    $DEBUG = true if ENV['DEBUG']
    t.rspec_opts = ["--colour", "--format", "documentation"]
    t.rspec_opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
    t.pattern = "spec/**/*_spec.rb"
  
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
