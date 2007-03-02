require 'singleton'
require 'find'
require 'yaml'
require File.dirname(__FILE__) + '/code_object'
require File.dirname(__FILE__) + '/source_parser'

module YARD
  class Namespace
    DEFAULT_YARDOC_FILE = "_Yardoc"
    
    include Singleton
    
    class << self
      ##
      # Attempt to find a namespace and return it if it exists. Similar
      # to the {YARD::Namsepace::at} method but creates the namespace
      # as a module if it does not exist, and return it.
      #
      # @param [String] namespace the namespace to search for.
      # @return [CodeObject] the namespace that was found or created.
      def find_or_create_namespace(namespace)
        return at(namespace) if at(namespace)
        name = namespace.split("::").last
        object = ModuleObject.new(name)
        instance.namespace.update(namespace => object)
        object
      end
      
      def add_object(object)
        instance.add_object(object)
      end
      
      def at(name)
        instance.at(name)
      end
      alias_method :[], :at
      
      def root
        at('')
      end
      
      def all
        instance.namespace.keys
      end
      
      def each_object
        instance.namespace.each do |name, object|
          yield(name, object)
        end
      end
      
      def load(file = DEFAULT_YARDOC_FILE, reload = false)
        if File.exists?(file) && !reload
          instance.namespace.replace(Marshal.load(IO.read(file)))
        else
          Find.find(".") do |path|
            SourceParser.parse(path) if path =~ /\.rb$/
          end
        end
        save
      end
      
      def save(file = DEFAULT_YARDOC_FILE)
        File.open(file, "w") {|f| Marshal.dump(instance.namespace, f) }
      end
      
      def find_from_path(object, name)
        object = at(object) unless object.is_a? CodeObject
        return object if name == 'self'
        
        while object
          ["::", ""].each do |type|
            obj = at(object.path + type + name)
            return obj if obj
          end
          object = object.parent
        end
        nil
      end
    end
    
    attr_reader :namespace
    
    def initialize
      @namespace = { '' => CodeObjectWithMethods.new('', :root) }
    end
    
    def add_object(object)
      return object if namespace[object.path] && object.docstring.nil?
      namespace.update(object.path => object)
      object
    end
    
    def at(name)
      namespace[name]
    end
  end
end