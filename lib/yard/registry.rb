require 'singleton'

module YARD
  class Registry
    include Singleton
  
    def self.at(path) instance.at(path) end
    def self.root; instance.root end
    def self.register(object) instance.register(object) end
    def self.delete(object) instance.delete(object) end
    def self.clear; instance.clear end

    def at(path) namespace[path] end
    def root; namespace[:root] end
    def delete(object) namespace.delete(object.path) end
    def clear; initialize end

    def initialize
      @namespace = SymbolHash.new
      @namespace[:root] = CodeObjects::ModuleObject.new(nil, :root)
    end
  
    def register(object)
      return if object.is_a?(CodeObjects::Proxy)
      namespace[object.path] = object
    end

    private
  
    attr_accessor :namespace
    
  end
end