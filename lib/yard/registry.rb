require 'singleton'

module YARD
  class Registry
    include Singleton
  
    @objects = {}

    class << self
      attr_reader :objects

      def all; instance.all end
      def at(path) instance.at(path) end
      def root; instance.root end
      def register(object) instance.register(object) end
      def delete(object) instance.delete(object) end
      
      def clear
        instance.clear 
        objects.clear
      end
      
      def resolve(namespace, name, proxy_fallback = false)
        while namespace
          [CodeObjects::NSEP, CodeObjects::ISEP].each do |s|
            path = name
            if namespace != root
              path = [namespace.path, name].join(s)
            end
            found = at(path)
            return found if found
          end
          namespace = namespace.parent
        end
        proxy_fallback ? P(namespace, name) : nil
      end
    end

    def all; namespace.keys.reject {|x| x == :root } end
    def at(path) path.to_s.empty? ? root : namespace[path] end
    def root; namespace[:root] end
    def delete(object) namespace.delete(object.path) end
    def clear; initialize end

    def initialize
      @namespace = SymbolHash.new
      @namespace[:root] = CodeObjects::ModuleObject.new(nil, :root)
      class << @namespace[:root]
        def path; "" end # root namespace has no path.
      end
    end
  
    def register(object)
      return if object.is_a?(CodeObjects::Proxy)
      namespace[object.path] = object
    end

    private
  
    attr_accessor :namespace
    
  end
end