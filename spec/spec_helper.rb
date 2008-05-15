require "rubygems"
require "spec"

module YARD
  def self.level
    Logger::INFO
  end
end

require File.join(File.dirname(__FILE__), '..', 'lib', 'yard')

def parse_file(file, thisfile = __FILE__)
  Registry.clear
  path = File.join(File.dirname(thisfile), 'examples', file.to_s + '.rb.txt')
  p = YARD::Parser::SourceParser.new
  p.parse(path)
  p
end

include YARD