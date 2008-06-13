require 'rubygems'
require 'erubis'
require 'erubis/tiny'
require 'erb'
require "benchmark"
require File.join(File.dirname(__FILE__), '..', 'lib', 'yard')

def rungen
  YARD::Registry.clear
  YARD::CLI::Yardoc.run('--quiet', '--use-cache') 
end

Benchmark.bmbm do |x|
  x.report("erubis") do
    eval <<-eof
      class YARD::Generators::Base
        def erb(str) Erubis::Eruby.new(str) end
      end
    eof
    
    rungen
  end

  x.report("fast-erubis") do
    eval <<-eof
      class YARD::Generators::Base
        def erb(str) Erubis::FastEruby.new(str) end
      end
    eof
    
    rungen
  end

  x.report("tiny-erubis") do
    eval <<-eof
      class YARD::Generators::Base
        def erb(str) Erubis::TinyEruby.new(str) end
      end
    eof
    
    rungen
  end

  x.report("erb")  do
    eval <<-eof
      class YARD::Generators::Base
        def erb(str) ERB.new(str, nil, '<>') end
      end
    eof
    
    rungen
  end
end