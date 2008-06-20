module YARD
  module CodeObjects
    class ProxyMethodError < NoMethodError; end

    class Proxy    
      def self.===(other) other.is_a?(self) end

      attr_reader :namespace, :name
      alias_method :parent, :namespace

      # @raise ArgumentError if namespace is not a NamespaceObject
      def initialize(namespace, name)
        namespace = Registry.root if !namespace || namespace == :root
        
        if name =~ /^#{NSEP}/
          namespace = Registry.root
          name = name[2..-1]
        end
        
        if name =~ /(?:#{NSEP}|#{ISEP})([^#{NSEP}#{ISEP}]+)$/
          @orignamespace, @origname = namespace, name
          @imethod = true if name.include? ISEP
          namespace = $`.empty? ? Registry.root : Proxy.new(namespace, $`)
          name = $1
        end 

        @name = name.to_sym
        @namespace = namespace
        
        unless @namespace.is_a?(NamespaceObject) or @namespace.is_a?(Proxy)
          raise ArgumentError, "Invalid namespace object: #{namespace}"
        end
        
        # If the name begins with "::" (like "::String")
        # this is definitely a root level object, so
        # remove the namespace and attach it to the root
        if @name =~ /^#{NSEP}/
          @name.gsub!(/^#{NSEP}/, '')
          @namespace = Registry.root
        end
      end
      
      def inspect
        if obj = to_obj
          obj.inspect
        else
          "P(#{path})"
        end
      end
      
      def path
        if obj = to_obj
          obj.path
        else
          if @namespace == Registry.root
            (@imethod ? ISEP : "") + name.to_s
          else
            @origname || name.to_s
          end
        end
      end
      alias to_s path
    
      def is_a?(klass)
        if obj = to_obj
          obj.is_a?(klass)
        else
          self.class <= klass
        end
      end
      
      def ===(other)
        if obj = to_obj
          obj === other
        else
          self.class <= other.class
        end
      end
      
      def <=>(other)
        if other.respond_to? :path
          path <=> other.path
        else
          false
        end
      end
      
      def ==(other)
        if other.respond_to? :path
          path == other.path
        else
          false
        end
      end
      
      def class
        if obj = to_obj
          obj.class
        else
          Proxy
        end
      end
      
      def type
        if obj = to_obj
          obj.type
        else
          Registry.proxy_types[path] || :proxy
        end
      end
      def type=(type) Registry.proxy_types[path] = type.to_sym end
      
      def instance_of?(klass)
        self.class == klass
      end
      
      def kind_of?(klass)
        self.class <= klass
      end

      def object_id
        if obj = to_obj
          obj.object_id
        else
          nil
        end
      end
      
      def respond_to?(meth, include_private = false)
        if obj = to_obj
          obj.respond_to?(meth, include_private)
        else
          super
        end
      end

      # Dispatches the method to the resolved object
      # 
      # @raise NoMethodError if the proxy cannot find the real object
      def method_missing(meth, *args, &block)
        if obj = to_obj
          obj.__send__(meth, *args, &block)
        else
          log.warn "Load Order / Name Resolution Problem on #{path}:"
          log.warn "-"
          log.warn "Something is trying to access the object #{path} before it has been recognized."
          log.warn "This error usually means that you need to modify the order in which you parse files"
          log.warn "so that #{path} is parsed before methods or other objects attempt to access it."
          log.warn "-"
          log.warn "YARD will recover from this error and continue to parse but you *may* have problems"
          log.warn "with your generated documentation. You should probably fix this."
          log.warn "-"
          begin 
            super
          rescue NoMethodError
            raise ProxyMethodError, "Proxy cannot call method ##{meth} on object '#{path}'"
          end
        end
      end
    
      private
    
      # Attempts to find the object that this unresolved object
      # references by checking if any objects by this name are
      # registered all the way up the namespace tree.
      # 
      # @return [Base, nil] the registered code object or nil
      def to_obj
        @obj ||= Registry.resolve(@namespace, @name)
      end
    end
  end
end

# Shortcut for creating a YARD::CodeObjects::Proxy 
# via a path
# 
# @see YARD::CodeObjects::Proxy
# @see YARD::Registry::resolve
def P(namespace, name = nil)
  namespace, name = nil, namespace if name.nil?
  YARD::Registry.resolve(namespace, name, true)
end
