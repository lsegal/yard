module YARD::CodeObjects
  class Base  
    attr_reader :path, :name
    attr_accessor :namespace
          
    def initialize(namespace, name)
      if namespace && !namespace.is_a?(NamespaceObject)
        raise "Invalid namespace object"
      end

      @name = name
      @path = YARD::Path.new(self)
      self.namespace = namespace
    end
    
    def namespace=(obj)
      if @namespace
        @namespace.children.delete(self) 
        YARD::Registry.delete(self)
      end
        
      @namespace = obj
      
      if @namespace
        @namespace.children << self 
        YARD::Registry.register(self)
      end
    end
    
    alias_method :parent, :namespace
    alias_method :parent=, :namespace=
    
    def +(other)
      path + other
    end
    
  end
end