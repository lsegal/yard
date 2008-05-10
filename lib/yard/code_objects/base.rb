module YARD
  module CodeObjects
    class CodeObjectList < Array
      def initialize(owner)
        @owner = owner
      end
      
      def <<(value)
        if value.is_a? CodeObjects::Base
          super unless include?(value)
        elsif value.is_a?(String) || value.is_a?(Symbol)
          super P(@owner, value) unless include?(P(@owner, value))
        else
          raise ArgumentError, "#{value.class} is not a valid CodeObject"
        end
        self
      end
      
      def push(value)
        self << value
      end
      
      undef :unshift
    end
    
    NAMESPACE_SEPARATOR = '::'
    INSTANCE_METHOD_SEPARATOR = '#'
    
    class Base  
      attr_reader :name
      attr_accessor :namespace
      attr_reader :source, :file, :line, :docstring
      attr_reader :tags
      
      class << self
        attr_accessor :instances
        
        def new(namespace, name, *args, &block)
          self.instances ||= {}
          keyname = "#{namespace && namespace.respond_to?(:path) ? namespace.path : ''}+#{name.inspect}"
          if obj = Registry.objects[keyname]
            obj
          else
            Registry.objects[keyname] = super(namespace, name, *args, &block)
          end
        end
      end
          
      def initialize(namespace, name)
        if namespace && namespace != :root && !namespace.is_a?(NamespaceObject)
          raise ArgumentError, "Invalid namespace object: #{namespace}"
        end

        @name = name
        @tags = []
        @docstring = ""
        self.namespace = namespace
        yield(self) if block_given?
      end
      
      def [](key)
        if respond_to?(key)
          send(key)
        else
          instance_variable_get("@#{key}")
        end
      end
      
      def []=(key, value)
        if respond_to?("#{key}=")
          send("#{key}=", value)
        else
          instance_variable_set("@#{key}", value)
        end
      end

      ##
      # Attaches source code to a code object with an optional file location
      #
      # @param [Statement, String] statement 
      #   the +Statement+ holding the source code or the raw source 
      #   as a +String+ for the definition of the code object only (not the block)
      def source=(statement)
        if statement.is_a? Statement
          @source = statement.tokens.to_s + (statement.block ? statement.block.to_s : "")
          self.line = statement.tokens.first.line_no
        else
          @source = statement.to_s
        end
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