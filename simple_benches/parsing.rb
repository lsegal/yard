require "benchmark"
require 'lib/yard'

Benchmark.bmbm do |x|
  x.report("parse in order") { YARD::Registry.clear; YARD.parse YARD::PATH_ORDER, Logger::ERROR } 
  x.report("parse") { YARD::Registry.clear; YARD.parse 'lib/**/*.rb', Logger::ERROR } 
end

=begin
load_order branch (2008-06-07):

Rehearsal --------------------------------------------------
parse in order   6.510000   0.050000   6.560000 (  6.563223)
parse            6.300000   0.040000   6.340000 (  6.362272)
---------------------------------------- total: 12.900000sec

                     user     system      total        real
parse in order   6.310000   0.060000   6.370000 (  6.390945)
parse            6.300000   0.050000   6.350000 (  6.366709)
=end

