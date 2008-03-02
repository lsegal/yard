require 'singleton'

class YARD::Registry
  include Singleton
  
  def self.at(path)
    instance.at(path)
  end
  
  def self.root
    instance.root
  end
  
  def self.register(object)
    instance.register(object)
  end
  
  def self.delete(object)
    instance.delete(object)
  end

  def initialize
    @namespace = SymbolHash.new
    @namespace[''] = YARD::CodeObjects::NamespaceObject.new(nil, :"!root!")
  end
  
  def at(path)
    namespace[path]
  end
  
  def root
    namespace['']
  end
  
  def register(object)
    namespace[object.path] = object
  end
  
  def delete(object)
    namespace.delete(object.path)
  end
  
  private
  
  attr_accessor :namespace
    
end