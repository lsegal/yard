module YARD
  module CodeObjects
    NAMESPACE_SEPARATOR = '::'
    INSTANCE_METHOD_SEPARATOR = '#'
    
    class Base  
      attr_reader :name
      attr_accessor :namespace
          
      def initialize(namespace, name)
        if namespace && namespace != :root && !namespace.is_a?(NamespaceObject)
          raise ArgumentError, "Invalid namespace object: #{namespace}"
        end

        @name = name
        self.namespace = namespace
        yield(self) if block_given?
      end
      
      # Default type is the lowercase class name without the "Object" suffix
      # 
      # Override this method to provide a custom object type 
      # 
      # @return [String] the type of code object this represents
      def type
        self.class.name.split(/::/).last.gsub(/Object$/, '').downcase
      end
    
      def path
        if parent && parent != Registry.root
          [parent.path.to_s, name.to_s].join(sep).to_sym
        else
          name
        end
      end
    
      def namespace=(obj)
        if @namespace
          @namespace.children.delete(self) 
          Registry.delete(self)
        end
        
        @namespace = (obj == :root ? Registry.root : obj)
      
        if @namespace
          @namespace.children << self 
          Registry.register(self)
        end
      end
    
      alias_method :parent, :namespace
      alias_method :parent=, :namespace=
    
      protected
    
      def sep; NAMESPACE_SEPARATOR end
    end
  end
end