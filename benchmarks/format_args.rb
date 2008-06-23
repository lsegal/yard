require "benchmark"
require 'lib/yard'

def format_args_regex(object)
  if object.signature
    object.signature[/#{Regexp.quote object.name.to_s}\s*(.*)/, 1]
  else
    ""
  end
end

def format_args_parameters(object)
  if !object.parameters.empty?
    args = object.parameters.map {|n, v| v ? "#{n} = #{v}" : n.to_s }.join(", ")
    "(#{args})"
  else
    ""
  end
end

YARD::Registry.load
$object = YARD::Registry.at('YARD::Generators::Base#G')

puts "regex:  " + format_args_regex($object)
puts "params: " + format_args_parameters($object)
puts

TIMES = 100_000
Benchmark.bmbm do |x|
  x.report("regex")      { TIMES.times { format_args_regex($object) } }
  x.report("parameters") { TIMES.times { format_args_parameters($object) } }
end


