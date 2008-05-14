require 'singleton'

module YARD
  class Registry
    include Singleton
  
    @objects = {}

    class << self
      attr_reader :objects

      def method_missing(meth, *args, &block)
        if instance.respond_to? meth
          instance.send(meth, *args, &block)
        else
          super
        end
      end
      
      def clear
        instance.clear 
        objects.clear
      end
      
      def resolve(namespace, name, proxy_fallback = false)
        namespace = Registry.root if namespace == :root || !namespace
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
        proxy_fallback ? CodeObjects::Proxy.new(namespace, name) : nil
      end
    end

    def all(*types)
      namespace.select do |k,v| 
        if types.empty?
          k != :root
        else
          k != :root &&
            types.any? do |type| 
              type.is_a?(Symbol) ? v.type == type : v.is_a?(type)
            end
        end
      end
    end
      
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