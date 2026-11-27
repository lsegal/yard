# frozen_string_literal: true
#
# Benchmark comparing Prism and Ripper parser backends for YARD.
#
# Usage:
#   ruby benchmark/prism_vs_ripper.rb
#   ruby benchmark/prism_vs_ripper.rb path/to/file.rb   # single file
#   ruby benchmark/prism_vs_ripper.rb path/to/dir        # directory

require "benchmark"
require "stringio"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
begin require "prism"; rescue LoadError; end
begin require "ripper"; rescue LoadError; end
require "yard"

abort "Prism is not available (Ruby >= 3.3 required)" unless defined?(Prism)
abort "Ripper is not available" unless defined?(Ripper)

# Collect files to parse
target = ARGV[0] || File.expand_path("../lib", __dir__)
if File.directory?(target)
  files = Dir[File.join(target, "**/*.rb")].sort
elsif File.file?(target)
  files = [target]
else
  abort "Not found: #{target}"
end

sources = files.map { |f| [f, File.read(f)] }
total_lines = sources.sum { |_, s| s.count("\n") }
total_bytes = sources.sum { |_, s| s.bytesize }

puts "YARD Parser Benchmark: Prism vs Ripper"
puts "=" * 50
puts "Ruby:    #{RUBY_VERSION} (#{RUBY_ENGINE})"
puts "Prism:   #{Prism::VERSION}"
puts "Files:   #{sources.size}"
puts "Lines:   #{total_lines}"
puts "Bytes:   #{total_bytes} (#{(total_bytes / 1024.0).round(1)} KB)"
puts

# ---------- Single-file parse (no handlers) ----------

puts "--- Raw parse (no handler processing) ---"
puts

iterations = sources.size < 10 ? 100 : 10

Benchmark.bm(12) do |x|
  x.report("Prism:") do
    iterations.times do
      sources.each do |file, source|
        YARD::Parser::Ruby::PrismParser.new(source, file).parse
      end
    end
  end

  x.report("Ripper:") do
    iterations.times do
      sources.each do |file, source|
        YARD::Parser::Ruby::RipperParser.new(source, file).parse
      end
    end
  end
end

puts
puts "(#{iterations} iterations x #{sources.size} files = #{iterations * sources.size} parses)"

# ---------- Full YARD parse (with handlers) ----------

puts
puts "--- Full YARD.parse (with handler processing) ---"
puts

iterations_full = sources.size < 10 ? 20 : 3

YARD::Logger.instance.io = StringIO.new
YARD::Logger.instance.level = YARD::Logger::ERROR

orig = YARD::Parser::Ruby::RubyParser.instance_method(:use_prism?)

Benchmark.bm(12) do |x|
  x.report("Prism:") do
    YARD::Parser::Ruby::RubyParser.define_method(:use_prism?) { true }
    iterations_full.times do
      YARD::Registry.clear
      YARD.parse(files)
    end
  end

  x.report("Ripper:") do
    YARD::Parser::Ruby::RubyParser.define_method(:use_prism?) { false }
    iterations_full.times do
      YARD::Registry.clear
      YARD.parse(files)
    end
  end
end

YARD::Parser::Ruby::RubyParser.define_method(:use_prism?, orig)

puts
puts "(#{iterations_full} iterations x #{sources.size} files = #{iterations_full * sources.size} parses)"

# ---------- Object-by-object sanity check ----------

puts
puts "--- Object parity check ---"

YARD::Logger.instance.io = StringIO.new

YARD::Registry.clear
YARD::Parser::Ruby::RubyParser.define_method(:use_prism?) { true }
YARD.parse(files)
prism_objects = YARD::Registry.all.map { |o|
  [o.path, o.class.name.split("::").last, o.respond_to?(:visibility) ? o.visibility : nil, o.docstring.to_s]
}.sort_by(&:first)

YARD::Registry.clear
YARD::Parser::Ruby::RubyParser.define_method(:use_prism?) { false }
YARD.parse(files)
ripper_objects = YARD::Registry.all.map { |o|
  [o.path, o.class.name.split("::").last, o.respond_to?(:visibility) ? o.visibility : nil, o.docstring.to_s]
}.sort_by(&:first)

YARD::Parser::Ruby::RubyParser.define_method(:use_prism?, orig) rescue nil

prism_set = prism_objects.map(&:first)
ripper_set = ripper_objects.map(&:first)
missing = ripper_set - prism_set
extra = prism_set - ripper_set

prism_map = prism_objects.group_by(&:first)
ripper_map = ripper_objects.group_by(&:first)
common = prism_set & ripper_set
vis_diffs = common.select { |p|
  prism_map[p].first[2] != ripper_map[p].first[2]
}.map { |p| "  #{p}: prism=#{prism_map[p].first[2]} ripper=#{ripper_map[p].first[2]}" }

doc_diffs = common.select { |p|
  prism_map[p].first[3] != ripper_map[p].first[3]
}.map { |p|
  pd = prism_map[p].first[3]
  rd = ripper_map[p].first[3]
  "  #{p}:\n    prism:  #{pd.inspect[0,80]}\n    ripper: #{rd.inspect[0,80]}"
}

puts "Prism objects:  #{prism_set.size}"
puts "Ripper objects: #{ripper_set.size}"

if missing.empty? && extra.empty? && vis_diffs.empty? && doc_diffs.empty?
  puts "EXACT MATCH"
else
  missing.each { |p| puts "  MISSING: #{p}" } unless missing.empty?
  extra.each   { |p| puts "  EXTRA:   #{p}" } unless extra.empty?
  vis_diffs.each { |d| puts "  VIS:    #{d}" } unless vis_diffs.empty?
  puts "Docstring mismatches: #{doc_diffs.size}" unless doc_diffs.empty?
  doc_diffs.first(10).each { |d| puts d } unless doc_diffs.empty?
  puts "  ... and #{doc_diffs.size - 10} more" if doc_diffs.size > 10
end
