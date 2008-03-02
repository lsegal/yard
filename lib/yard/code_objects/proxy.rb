module YARD
  module CodeObjects
    class Proxy 
      # Make this object a true proxy class by removing all Object methods except
      # for some sane defaults like __send__ (which we need)
      instance_methods.
        reject {|m| [:new, :inspect, :to_s, :__id__, :__send__].include? m.to_sym }.
        each {|name| class_eval "undef #{name.to_sym}" }
      
      #undef :type # Hack, Ruby 1.8.x still registers #type as an object method

      # @raise ArgumentError if namespace is not a NamespaceObject
      def initialize(namespace, name)
        @name = name.to_s
        @namespace = namespace
        @namespace = Registry.root if !namespace || namespace == :root
        
        unless @namespace.is_a?(NamespaceObject)
          raise ArgumentError, "Invalid namespace object: #{namespace}"
        end
        
        # If the name begins with "::" (like "::String")
        # this is definitely a root level object, so
        # remove the namespace and attach it to the root
        if @name =~ /^#{NAMESPACE_SEPARATOR}/
          @name.gsub!(/^#{NAMESPACE_SEPARATOR}/, '')
          @namespace = Registry.root
        end
      end
    
      def name; @name.to_sym end

      # Dispatches the method to the resolved object
      # 
      # @raise NoMethodError if the proxy cannot find the real object
      def method_missing(meth, *args, &block)
        if obj = to_obj
          obj.__send__(meth, *args, &block)
        else
          super
        end
      end
    
      private
    
      # Attempts to find the object that this unresolved object
      # references by checking if any objects by this name are
      # registered all the way up the namespace tree.
      # 
      # @return [Base, nil] the registered code object or nil
      def to_obj
        obj = @namespace
        while obj
          [NAMESPACE_SEPARATOR, ''].each do |s|
            path = @name
            if obj != Registry.root
              path = [obj.path.to_s, @name].join(s)
            end
            found = Registry.at(path)
            return found if found
          end
          obj = obj.parent
        end
        nil
      end
    end
  end
end

# Shortcut for creating a YARD::CodeObjects::Proxy 
# via a path
# 
# @see YARD::CodeObjects::Proxy
def P(namespace, name) 
  YARD::CodeObjects::Proxy.new(namespace, name)
end