require 'singleton'
require 'fileutils'
require 'digest/sha1'

module YARD
  # The +Registry+ is the centralized data store for all {CodeObjects} created
  # during parsing. The storage is a key value store with the object's path
  # (see {CodeObjects::Base#path}) as the key and the object itself as the value.
  # Object paths must be unique to be stored in the Registry. All lookups for 
  # objects are done on the singleton Registry instance using the {Registry#at} 
  # or {Registry#resolve} methods.
  # 
  # The registry is saved to a "yardoc" file, which can be loaded back to 
  # perform any lookups.
  # 
  # This class is a singleton class. Any method called on the class will be
  # delegated to the instance.
  class Registry 
    DEFAULT_YARDOC_FILE = ".yardoc"
    LOCAL_YARDOC_INDEX = File.expand_path('~/.yard/gem_index')
    
    include Singleton
  
    @objects = {}

    class << self
      # Holds the objects cache. This attribute should never be accessed
      # directly.
      # @return [Array<CodeObjects::Base>] the objects cache
      attr_reader :objects
      
      # Clears the registry and cache
      # @return [void] 
      def clear
        instance.clear 
        objects.clear
      end

      # Returns the .yardoc file associated with a gem.
      # 
      # @param [String] gem the name of the gem to search for
      # @param [String] ver_require an optional Gem version requirement
      # @param [Boolean] for_writing whether or not the method should search
      #   for writable locations
      # @return [String] if +for_writing+ is set to +true+, returns the best 
      #   location suitable to write the .yardoc file. Otherwise, the first 
      #   existing location associated with the gem's .yardoc file.
      # @return [nil] if +for_writing+ is set to false and no yardoc file
      #   is found, returns nil.
      def yardoc_file_for_gem(gem, ver_require = ">= 0", for_writing = false)
        spec = Gem.source_index.find_name(gem, ver_require)
        return if spec.empty?
        spec = spec.first
        
        if gem =~ /^yard-doc-/
          path = File.join(spec.full_gem_path, DEFAULT_YARDOC_FILE)
          return File.exist?(path) && !for_writing ? path : nil
        end
        
        if for_writing
          global_yardoc_file(spec, for_writing) ||
            local_yardoc_file(spec, for_writing)
        else
          local_yardoc_file(spec, for_writing) ||
            global_yardoc_file(spec, for_writing)
        end
      end
      
      private
      
      def global_yardoc_file(spec, for_writing = false)
        path = spec.full_gem_path
        yfile = File.join(path, DEFAULT_YARDOC_FILE)
        if for_writing && File.writable?(path)
          return yfile
        elsif !for_writing && File.exist?(yfile)
          return yfile
        end
      end
      
      def local_yardoc_file(spec, for_writing = false)
        path = Registry::LOCAL_YARDOC_INDEX
        FileUtils.mkdir_p(path) if for_writing
        path = File.join(path, "#{spec.full_name}.yardoc")
        if for_writing
          path
        else
          File.exist?(path) ? path : nil
        end
      end
    end

    # Gets/sets the yardoc filename
    # @return [String] the yardoc filename
    # @see DEFAULT_YARDOC_FILE
    attr_accessor :yardoc_file
    
    # The assumed types of a list of paths
    # @return [{String => Symbol}] a set of unresolved paths and their assumed type
    def proxy_types
      @store.proxy_types
    end
    
    # Loads the registry and/or parses a list of files
    # 
    # @example Loads the yardoc file or parses files 'a', 'b' and 'c' (but not both)
    #   Registry.load(['a', 'b', 'c'])
    # @example Reparses files 'a' and 'b' regardless if yardoc file exists
    #   Registry.load(['a', 'b'], true)
    # @param [String, Array] files if +files+ is an Array, it should represent
    #   a list of files that YARD should parse into the registry. If reload is
    #   set to false and the yardoc file already exists, these files are skipped.
    #   If files is a String, it should represent the yardoc file to load
    #   into the registry.
    # @param [Boolean] reload if reload is false and a yardoc file already
    #   exists, any files passed in will be ignored.
    # @return [Boolean] true if the registry was successfully loaded 
    # @raise [ArgumentError] if files is not a String or Array
    def load(files = [], reload = false)
      if files.is_a?(Array)
        if File.exists?(yardoc_file) && !reload
          load_yardoc
        else
          size = @store.keys.size
          YARD.parse(files)
          save if @store.keys.size > size
        end
        true
      elsif files.is_a?(String)
        load_yardoc(files)
        true
      else
        raise ArgumentError, "Must take a list of files to parse or the .yardoc file to load."
      end
    end
    
    # Loads a yardoc file directly
    # 
    # @param [String] file the yardoc file to load.
    # @return [void] 
    def load_yardoc(file = yardoc_file)
      clear
      @store.load(file)
    end
    
    def load!(file = yardoc_file)
      clear
      @store.load!(file)
    end
    
    def load_all
      @store.load_all
    end

    # Saves the registry to +file+
    # 
    # @param [String] file the yardoc file to save to
    # @return [Boolean] true if the file was saved
    def save(merge = false, file = yardoc_file)
      @store.save(merge, file)
    end
    
    def checksums
      @store.checksums
    end
    
    def checksum_for(data)
      Digest::SHA1.hexdigest(data)
    end
    
    def delete_from_disk
      @store.destroy
    end

    # Returns all objects in the registry that match one of the types provided
    # in the +types+ list (if +types+ is provided).
    # 
    # @example Returns all objects
    #   Registry.all
    # @example Returns all classes and modules
    #   Registry.all(:class, :module)
    # @param [Array<Symbol>] types an optional list of types to narrow the
    #   objects down by. Equivalent to performing a select: 
    #     +Registry.all.select {|o| types.include(o.type) }+
    # @return [Array<CodeObjects::Base>] the list of objects found
    # @see CodeObjects::Base#type
    def all(*types)
      @store.values.select do |obj| 
        if types.empty?
          obj != root
        else
          obj != root &&
            types.any? do |type| 
              type.is_a?(Symbol) ? obj.type == type : obj.is_a?(type)
            end
        end
      end + (types.include?(:root) ? [root] : [])
    end
    
    # Returns the paths of all of the objects in the registry.
    # @param [Boolean] reload whether to load entire database
    # @return [Array<String>] all of the paths in the registry.
    def paths(reload = false)
      @store.keys(reload).map {|k| k.to_s }
    end
    
    # Returns the object at a specific path.
    # @param [String, :root] path the pathname to look for. If +path+ is +root+,
    #   returns the {#root} object.
    # @return [CodeObjects::Base] the object at path
    # @return [nil] if no object is found
    def at(path) @store[path] end
    alias_method :[], :at
    
    # The root namespace object.
    # @return [CodeObjects::RootObject] the root object in the namespace
    def root; @store[:root] end
    
    # Deletes an object from the registry
    # @param [CodeObjects::Base] object the object to remove
    # @return [void] 
    def delete(object) 
      @store.delete(object.path)
      self.class.objects.delete(object.path)
    end

    # Clears the registry
    # @return [void] 
    def clear
      @store = RegistryStore.new
    end

    # Creates the Registry
    # @return [Registry]
    def initialize
      @yardoc_file = DEFAULT_YARDOC_FILE
      clear
    end
  
    # Registers a new object with the registry
    # 
    # @param [CodeObjects::Base] object the object to register
    # @return [CodeObjects::Base] the registered object
    def register(object)
      self.class.objects[object.path] = object
      return if object.is_a?(CodeObjects::Proxy)
      @store[object.path] = object
    end

    # Attempts to find an object by name starting at +namespace+, performing
    # a lookup similar to Ruby's method of resolving a constant in a namespace.
    # 
    # @example Looks for instance method #reverse starting from A::B::C
    #   Registry.resolve(P("A::B::C"), "#reverse")
    # @example Looks for a constant in the root namespace
    #   Registry.resolve(nil, 'CONSTANT')
    # @example Looks for a class method respecting the inheritance tree
    #   Registry.resolve(myclass, 'mymethod', true)
    # @example Looks for a constant but returns a proxy if not found
    #   Registry.resolve(P('A::B::C'), 'D', false, true) # => #<yardoc proxy A::B::C::D>
    # @example Looks for a complex path from a namespace
    #   Registry.resolve(P('A::B'), 'B::D') # => #<yardoc class A::B::D>
    # @param [CodeObjects::NamespaceObject, nil] namespace the starting namespace
    #   (module or class). If +nil+ or +:root+, starts from the {#root} object.
    # @param [String, Symbol] name the name (or complex path) to look for from
    #   +namespace+.
    # @param [Boolean] inheritance Follows inheritance chain (mixins, superclass)
    #   when performing name resolution if set to +true+.
    # @param [Boolean] proxy_fallback If +true+, returns a proxy representing
    #   the unresolved path (namespace + name) if no object is found.
    # @return [CodeObjects::Base] the object if it is found
    # @return [CodeObjects::Proxy] a Proxy representing the object if 
    #   +proxy_fallback+ is +true+.
    # @return [nil] if +proxy_fallback+ is +false+ and no object was found.
    # @see P
    def resolve(namespace, name, inheritance = false, proxy_fallback = false)
      if namespace.is_a?(CodeObjects::Proxy)
        return proxy_fallback ? CodeObjects::Proxy.new(namespace, name) : nil
      end
      
      if namespace == :root || !namespace
        namespace = root
      else
        namespace = namespace.parent until namespace.is_a?(CodeObjects::NamespaceObject)
      end
      orignamespace = namespace

      name = name.to_s
      if name =~ /^#{CodeObjects::NSEPQ}/
        [name, name[2..-1]].each do |n|
          return at(n) if at(n)
        end
      else
        while namespace
          if namespace.is_a?(CodeObjects::NamespaceObject)
            nss = inheritance ? namespace.inheritance_tree(true) : [namespace]
            nss.each do |ns|
              next if ns.is_a?(CodeObjects::Proxy)
              found = partial_resolve(ns, name)
              return found if found
            end
          end
          namespace = namespace.parent
        end

        # Look for ::name or #name in the root space
        [CodeObjects::ISEP, CodeObjects::NSEP].each do |s|
          found = at(s + name)
          return found if found
        end
      end
      proxy_fallback ? CodeObjects::Proxy.new(orignamespace, name) : nil
    end
    
    # Define all instance methods as singleton methods on instance
    (public_instance_methods(false) - public_methods(false)).each do |meth|
      module_eval(<<-eof, __FILE__, __LINE__ + 1) 
        def self.#{meth}(*args, &block) instance.send(:#{meth}, *args, &block) end
      eof
    end

    private

    # Attempts to resolve a name in a namespace
    # 
    # @param [CodeObjects::NamespaceObject] namespace the starting namespace
    # @param [String] name the name to look for
    def partial_resolve(namespace, name)
      [CodeObjects::NSEP, CodeObjects::CSEP, ''].each do |s|
        next if s.empty? && name =~ /^\w/
        path = name
        if namespace != root
          path = [namespace.path, name].join(s)
        end
        found = at(path)
        return found if found
      end
      nil
    end
  end
end