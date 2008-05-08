require 'singleton'

module YARD
  class Registry
    include Singleton
  
    @objects = {}

    class << self
      attr_reader :objects

      def at(path) instance.at(path) end
      def root; instance.root end
      def register(object) instance.register(object) end
      def delete(object) instance.delete(object) end
      
      def clear
        instance.clear 
        objects.clear
      end
    end

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