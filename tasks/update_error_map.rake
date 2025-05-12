# frozen_string_literal: true

# Script to generate the Error class name map in:
# lib/yard/handlers/c/base.rb

require 'open-uri'
require 'stringio'

desc 'Update the error class names map'
task :update_error_map do
  error_c_url = 'https://raw.githubusercontent.com/ruby/ruby/master/error.c'

  init_match = /void\s+Init_Exception\(void\)\s*\{(.+?)^\}/m
  name_match = /(\w+)\s*=\s*rb_define_class\("([^"]+)"/

  $stderr.puts "Downloading #{error_c_url} ..."
  content = open(error_c_url, &:read) # rubocop:disable Security/Open

  $stderr.puts "Extracting class names ..."
  init_source = content.match(init_match).captures.first
  map = init_source.scan(name_match).sort_by {|key, _value| key }

  $stderr.puts "Generating new lookup table ..."
  indent = '  ' * 4
  source = StringIO.new
  source.puts "#{indent}ERROR_CLASS_NAMES = {"
  map.each do |variable, name|
    source.puts "#{indent}  '#{variable}' => '#{name}',"
  end
  source.puts "#{indent}}"

  $stderr.puts source.string

  $stderr.puts "Patching 'lib/yard/handlers/c/base.rb' ..."
  class_name_map_match = /^\s+ERROR_CLASS_NAMES = {[^}]+}/

  project_path = File.expand_path('..', __dir__)
  c_base_handler = File.join(project_path, 'lib/yard/handlers/c/base.rb')

  File.open(c_base_handler, 'r+') do |file|
    content = file.read
    # .rstrip is added to avoid adding new empty lines due to the new lines
    # added by `.puts` when building the string.
    content.gsub!(class_name_map_match, source.string.rstrip)
    file.rewind
    file.truncate(0)
    file.write(content)
  end

  $stderr.puts "Done!"
end
