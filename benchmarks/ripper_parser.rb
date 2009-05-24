# encoding: utf-8
require 'benchmark'
require File.dirname(__FILE__) + '/../lib/yard'
require 'yard/parser/ruby/legacy/ruby_lex' unless RUBY18

class YARD::Parser::SourceParser
  def top_level_parse(statements) statements end
end

$files_yard = Dir[File.dirname(__FILE__) + '/../lib/**/*.rb'].map {|f| File.read(f) }
$files_rip = Dir[File.dirname(__FILE__) + '/../lib/**/*.rb'].map {|f| [File.read(f), f] }

TIMES = 2
Benchmark.bmbm do |x|
  x.report("yard-parser  ") { TIMES.times { $files_yard.each {|f| YARD::Parser::Ruby::Legacy::StatementList.new(f) } } }
  x.report("rip-parser") { TIMES.times { $files_rip.each {|f| YARD::Parser::Ruby::RubyParser.parse(*f) } } }
  #x.report("old-ripper-parser") { $files.each {|f| OldRipper::RipperSexp.parse(f) } }
end