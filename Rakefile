# frozen_string_literal: true
require File.dirname(__FILE__) + '/lib/yard'
require File.dirname(__FILE__) + '/lib/yard/rubygems/specification'
require 'rbconfig'

YARD::VERSION.replace(ENV['YARD_VERSION']) if ENV['YARD_VERSION']

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
rescue LoadError
  nil # noop
end

desc "Check code style with Rubocop"
task :rubocop do
  sh "rubocop"
end

desc "Generate documentation for Yard, and fail if there are any warnings"
task :test_doc do
  sh "ruby bin/yard --fail-on-warning #{"--no-progress" if ENV["CI"]}"
end

task :default => [:rubocop, :spec, :test_doc]

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "YARD #{YARD::VERSION} Documentation"]
end

namespace :release do
  def release_version
    unless defined?(@__release_version)
      ver = ENV['VERSION']

      raise "missing VERSION=x.y.z" if ver.nil? || ver.empty?
      if ver < YARD::VERSION
        raise "invalid version `#{ver}' (must be >= `#{YARD::VERSION}')"
      end

      @__release_version = ENV['VERSION']
    end

    @__release_version
  end

  def word_wrap(text)
    text.gsub(/(.{1,60})(\s|$)/, "\\1\n  ")
  end

  def collect_issues
    devnull = YARD.windows? ? "NUL" : "/dev/null"
    prevtag = `git describe --tags --abbrev=0`.strip
    out = `git log #{prevtag}...HEAD -E --grep "#[0-9]+" 2>#{devnull}`
    out.scan(%r{((?:\S+\/\S+)?#\d+)}).flatten
  end

  def commit_message
    message = "Tag release v#{release_version}"

    issues = collect_issues
    unless issues.empty?
      message += "\n\nReferences:\n  " + word_wrap(issues.uniq.sort.join(", "))
    end

    message
  end

  desc "Tags a version"
  task :tag do
    ver = release_version
    vfile = File.join(File.dirname(__FILE__), 'lib', 'yard', 'version.rb')
    content = File.read(vfile)
    content = content.sub(/VERSION = '(.+?)'/, "VERSION = '#{ver}'")
    File.open(vfile, 'w') {|f| f.write(content) }

    day_ord = {1 => "st", 2 => "nd", 3 => "rd"}[Time.now.day % 10] || "th"
    chfile = File.join(File.dirname(__FILE__), 'CHANGELOG.md')
    content = File.read(chfile)
    repl = <<-eof
# master

# [#{ver}] - #{Time.now.strftime("%B %d#{day_ord}, %Y")}

[#{ver}]: https://github.com/lsegal/yard/compare/v\\2...v#{ver}

\\1

# [\\2]
eof
    content = content.sub(/\A\s*# master\r?\n(.*?)\r?\n# \[(.+?)\]/mis, repl.strip)
    File.open(chfile, 'w') {|f| f.write(content) }
    sh "git commit -m \"#{commit_message}\" -- lib/yard/version.rb CHANGELOG.md"
    sh "git tag -f v#{ver}"
  end

  desc 'Builds a release with VERSION=x.y.z'
  task :build do
    sh "docker build . -t yard-release/v#{release_version} -f Dockerfile.release --build-arg VERSION=#{release_version}"
  end

  desc 'Publishes a built release with VERSION=x.y.z'
  task :publish do
    sh "docker run -v #{Dir.home}/.samus:/root/.samus yard-release/v#{release_version} && docker rmi -f yard-release/v#{release_version} && git pull"
  end
end
