require 'singleton'

class YARD::Namespace
  include Singleton
  
  def self.at(path)
    instance.at(path)
  end
  
  def initialize
    @namespace = SymbolHash.new
  end
  
  def at(path)
    @namespace[path]
  end
    
end