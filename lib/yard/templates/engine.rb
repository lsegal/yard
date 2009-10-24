require 'pathname'

module YARD
  module Templates
    module Engine
      class << self
        # @return [Array<Pathname>] the list of registered template paths
        attr_accessor :template_paths

        # Registers a new template path in {template_paths}
        # 
        # @param [Pathname, String] path a new template path
        # @return [nil] 
        def register_template_path(path)
          template_paths.unshift Pathname.new(path)
        end
        
        # Creates a template module representing the path. Searches on disk 
        # for the first directory named +path+ (joined by '/') within the 
        # template paths and builds a template module for. All other matching 
        # directories in other template paths will be included in the 
        # generated module as mixins (for overriding).
        # 
        # @param [Array<String, Symbol>] path a list of path components
        # @return [Template] the module representing the template
        def template(*path)
          from_template = nil
          from_template = path.shift if path.first.is_a?(Template)
          path = path.join('/')
          full_paths = find_template_paths(from_template, path)
          
          path = path.gsub('../', '')
          raise ArgumentError, "No such template for #{path}" if full_paths.empty?
          mod = template!(path, full_paths.shift)
          full_paths.each do |full_path|
            mod.send(:include, template!(path, full_path))
          end
          
          mod
        end
        
        # Forces creation of a template at +path+ within a +full_path+.
        # 
        # @param [String] path the path name of the template
        # @param [String, Pathname] full_path the full path on disk of the template
        # @return [Template] the template module representing the +path+
        def template!(path, full_path = nil)
          full_path ||= path
          name = template_module_name(full_path)
          return const_get(name) rescue NameError 

          mod = const_set(name, Module.new)
          mod.send(:include, Template)
          mod.send(:initialize, path, full_path)
          mod
        end

        # Renders a template on a {CodeObjects::Base code object} using
        # a set of default (overridable) options. Either the +:object+
        # or +:type+ keys must be provided. 
        # 
        # If a +:serializer+ key is provided and +:serialize+ is not set to
        # false, the rendered contents will be serialized through the {Serializers::Base}
        # object. See {#with_serializer}.
        # 
        # @param [Hash] options the options hash
        # @option options [Symbol] :format (:text) the default format
        # @option options [Symbol] :type (nil) the :object's type.
        # @option options [Symbol] :template (:default) the default template
        # @return [String] the rendered template
        def render(options = {})
          set_default_options(options)
          mod = template(options[:template], options[:type], options[:format])
          
          if options[:serialize] != false
            with_serializer(options[:object], options[:serializer]) { mod.run(options) }
          else
            mod.run(options)
          end
        end
        
        # Passes a set of objects to the +:fulldoc+ template for full documentation generation. 
        # This is called by {CLI::Yardoc} to most commonly perform HTML 
        # documentation generation.
        # 
        # @param [Array<CodeObjects::Base>] objects a list of {CodeObjects::Base}
        #   objects to pass to the template
        # @param [Hash] options (see {#render})
        # @return [nil]
        def generate(objects, options = {})
          set_default_options(options)
          options[:objects] = objects
          template(options[:template], :fulldoc, options[:format]).run(options)
        end

        # Serializes the results of a block with a +serializer+ object.
        # 
        # @param [CodeObjects::Base] object the code object to serialize
        # @param [Serializers::Base] serializer the serializer object
        # @yield a block whose result will be serialize
        # @yieldreturn [String] the contents to serialize
        # @see Serializers::Base
        def with_serializer(object, serializer, &block)
          serializer.before_serialize if serializer
          output = yield
          if serializer
            serializer.serialize(object, output)
            serializer.after_serialize(output)
          end
          output
        end
        
        private
        
        # Sets default options on the options hash
        # 
        # @param [Hash] options the options hash
        # @option options [Symbol] :format (:text) the default format
        # @option options [Symbol] :type (nil) the :object's type, if provided
        # @option options [Symbol] :template (:default) the default template
        # @return [nil]
        def set_default_options(options = {})
          options[:format] ||= :text
          options[:type] ||= options[:object].type if options[:object]
          options[:template] ||= :default
        end

        # Searches through the registered {template_paths} and returns
        # all full directories that have the +path+ within them on disk.
        # 
        # @param [Template] from_template if provided, allows a relative
        #   path to be specified from this template's full path.
        # @param [String] path the path component to search for in the
        #   {template_paths}
        # @return [Array<Pathname>] a list of full paths that are existing
        #   candidates for a template module
        def find_template_paths(from_template, path)
          paths = template_paths.dup
          paths = from_template.full_paths + paths if from_template
          
          paths.inject([]) do |acc, tp|
            full_path = tp.join(path).cleanpath
            acc.unshift(full_path) if full_path.directory?
            acc
          end.uniq
        end

        # The name of the module that represents a +path+
        # 
        # @param [String, Pathname] the path toe generate a module name for
        # @return [String] the module name
        def template_module_name(path)
          'Template_' + path.to_s.gsub(/[^a-z0-9]/i, '_')
        end
      end

      self.template_paths = []
    end
    
    Engine.register_template_path(Pathname.new(YARD::ROOT).join('..', 'templates'))
  end
end
