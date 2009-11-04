require 'rubygems'
#require 'ruby-prof'
#require 'benchmark'
require File.join(File.dirname(__FILE__), '..', 'lib', 'yard')

YARD::Registry.load_yardoc(File.join(File.dirname(__FILE__), '..', '.yardoc'))
obj = YARD::Registry.at("YARD::CodeObjects::Base")

require 'perftools'
PerfTools::CpuProfiler.start("template_profile") do
  obj.format(:format => :html, :no_highlight => true)
end

# result = RubyProf.profile do
# end
# 
# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(STDOUT)
