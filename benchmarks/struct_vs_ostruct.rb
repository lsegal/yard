require 'benchmark'
require 'ostruct'
require_relative '../lib/yard'

n = 100000
class MyStruct < Struct.new(:a, :b, :c); end
ostruct = OpenStruct.new
yostruct = YARD::OpenStruct.new
mystruct = MyStruct.new

Benchmark.bmbm do |x|
  x.report("Struct.new(args)") { n.times { MyStruct.new 1, 2, 3 } }
  x.report("Struct (assign)") { n.times { mystruct.a = 1 } }
  x.report("Struct (read)") { n.times { mystruct.a } }
  x.report("OpenStruct.new(args)") { n.times { OpenStruct.new a: 1, b: 2, c: 3 } }
  x.report("OpenStruct.new (blank)") { n.times { OpenStruct.new } }
  x.report("OpenStruct (assign)") { n.times { ostruct.a = 1 } }
  x.report("OpenStruct (read)") { n.times { ostruct.a } }
  x.report("YARD::OpenStruct.new(args)") { n.times { YARD::OpenStruct.new a: 1, b: 2, c: 3 } }
  x.report("YARD::OpenStruct.new (blank)") { n.times { YARD::OpenStruct.new } }
  x.report("YARD::OpenStruct (assign)") { n.times { yostruct.a = 1 } }
  x.report("YARD::OpenStruct (read)") { n.times { yostruct.a } }
end
