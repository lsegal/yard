#!/usr/bin/env ruby

version = (ENV['REF'] || ENV['GITHUB_REF'] || '').sub(%r{\Arefs/tags/v}, '')
log = File.read(ENV['CHANGELOG'] || Dir.glob('CHANGELOG*').first)
rlsfile = ENV['RELEASE_FILE'] || '/github/home/.releasenotes'

match = /^#\s*\[#{version}\]\s+-\s+(?<title>.+?)\r?\n(?<body>.*?)\r?\n#/ms.match(log)
unless match
  puts "Skipping release, no Changelog notes found for v#{version}"
  exit 78
end

title = "Release: v#{version} (#{match.named_captures['title'].strip})"
body = match.named_captures['body'].strip
notes = "#{title}\n\n#{body}"

puts "Release Notes for v#{version}:"
puts ""
puts notes

File.open(rlsfile, 'w') {|f| f.write(notes) }

artifact_arg = ENV['ARTIFACT'] ? "-a #{ENV['ARTIFACT'].inspect}" : ''
ENV['GITHUB_TOKEN'] = ENV['RELEASE_TOKEN'] || ENV['GITHUB_TOKEN']
system "hub release create #{artifact_arg} -F #{rlsfile} v#{version}"
