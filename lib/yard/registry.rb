require 'singleton'
require 'find'

module YARD
  class Registry 
    DEFAULT_YARDOC_FILE = ".yardoc"
    
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
    end

    attr_accessor :yardoc_file
    attr_reader :proxy_types
    
    def load(files = [], reload = false)
      if files.is_a?(Array)
        if File.exists?(yardoc_file) && !reload
          load_yardoc
        else
          size = namespace.size
          YARD.parse(files)
          save if namespace.size > size
        end
        true
      elsif files.is_a?(String)
        load_yardoc(files)
        true
      else
        raise ArgumentError, "Must take a list of files to parse or the .yardoc file to load."
      end
    end
    
    def load_yardoc(file = yardoc_file)
      return false unless File.exists?(file)
      ns, pt = *Marshal.load(IO.read(file))
      namespace.update(ns)
      proxy_types.update(pt)
    end
    
    def save(file = yardoc_file)
      File.open(file, "w") {|f| Marshal.dump([@namespace, @proxy_types], f) }
      true
    end

    def all(*types)
      namespace.values.select do |obj| 
        if types.empty?
          obj != Registry.root
        else
          obj != Registry.root &&
            types.any? do |type| 
              type.is_a?(Symbol) ? obj.type == type : obj.is_a?(type)
            end
        end
      end
    end
    
    def paths
      namespace.keys.map {|k| k.to_s }
    end
      
    def at(path) path.to_s.empty? ? root : namespace[path] end
    alias_method :[], :at
    
    def root; namespace[:root] end
    def delete(object) namespace.delete(object.path) end

    def clear
      @namespace = SymbolHash.new
      @namespace[:root] = CodeObjects::RootObject.new(nil, :root)
      @proxy_types = {}
    end

    def initialize
      @yardoc_file = DEFAULT_YARDOC_FILE
      clear
    end
  
    def register(object)
      return if object.is_a?(CodeObjects::Proxy)
      namespace[object.path] = object
    end

    def resolve(namespace, name, proxy_fallback = false)
      if namespace.is_a?(CodeObjects::Proxy)
        return proxy_fallback ? CodeObjects::Proxy.new(namespace, name) : nil
      end
      
      namespace = root if namespace == :root || !namespace

      newname = name.to_s.gsub(/^#{CodeObjects::ISEP}/, '')
      if name =~ /^#{CodeObjects::NSEP}/
        [name, newname[2..-1]].each do |n|
          return at(n) if at(n)
        end
      else
        while namespace
          [CodeObjects::NSEP, CodeObjects::ISEP].each do |s|
            path = newname
            if namespace != root
              path = [namespace.path, newname].join(s)
            end
            found = at(path)
            return found if found
          end
          namespace = namespace.parent
        end

        # Look for ::name or #name in the root space
        [CodeObjects::NSEP, CodeObjects::ISEP].each do |s|
          found = at(s + newname)
          return found if found
        end
      end
      proxy_fallback ? CodeObjects::Proxy.new(namespace, name) : nil
    end

    private
  
    attr_accessor :namespace
    
  end
end