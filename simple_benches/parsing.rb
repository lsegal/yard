require "benchmark"
require 'lib/yard'

Benchmark.bmbm do |x|
  x.report("parse in order") { YARD::Registry.clear; YARD.parse YARD::PATH_ORDER, Logger::ERROR } 
  x.report("parse") { YARD::Registry.clear; YARD.parse 'lib/**/*.rb', Logger::ERROR } 
end