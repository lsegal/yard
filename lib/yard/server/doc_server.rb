module YARD
  module Server
    class ProjectLoadError < RuntimeError; end
    class FileLoadError < RuntimeError; end
    class ObjectLoadError < RuntimeError; end
    
    class DocServer
      include Templates::Helpers::BaseHelper
      include Templates::Helpers::ModuleHelper
      include DocServerUrlHelper
      
      # @return [Request] request object
      attr_accessor :request
      
      # @return [Hash{String => String}] response headers
      attr_accessor :headers
      
      # @return [Numeric] status code
      attr_accessor :status
      
      # @return [String] the response body
      attr_accessor :body
      
      # @return [String] the name of the project
      attr_accessor :project

      # @return [String] the path containing the yardoc file
      attr_reader :project_path

      # @return [String] the yardoc to use for lookups
      attr_accessor :yardoc_file
            
      # @return [Hash{Symbol => Object}] default options for the project
      attr_accessor :options
      
      # @return [Serializers::Base] the serializer used to perform file linking
      attr_accessor :serializer
      
      # @return [Boolean] whether router should route for multiple projects
      attr_accessor :single_project
      
      # @return [Array<Array(String, String)>] an associative array of projects
      #   and yardoc files.
      attr_accessor :projects
      
      def initialize(projects, single = false)
        self.projects = projects.to_a
        self.single_project = single
      end
      
      def call(request)
        self.project = nil
        self.yardoc_file = nil
        self.options = SymbolHash.new(false).update(
          :serialize => false,
          :markup => :rdoc,
          :format => :html
        )
        self.serializer = nil
        self.request = request
        self.headers = {'Content-Type' => 'text/html'}
        self.body = ''
        self.status = 200
        parse_uri
        [status, headers, body]
      end
      
      def project_path
        File.dirname(yardoc_file)
      end
      
      protected
      
      def display_object(path)
        setup_project

        object = Registry.at(path =~ /^toplevel(?:::|#|$)/ ? "" : path)
        options.update(:type => :layout)
        cache object.format(options)
      end
      
      def display_file(file)
        setup_project

        ppath = project_path
        filename = File.cleanpath(File.join(project_path, file))
        #p filename
        #raise FileLoadError if !File.file?(filename) || filename.index(project_path) != 0
        if filename =~ /\.(jpe?g|gif|png|bmp)$/i
          headers['Content-Type'] = "image/#{$1}"
          cache IO.read(filename)
        else
          options.update(:object => Registry.root, :type => :layout, :file => filename)
          cache YARD::Templates::Engine.render(options)
        end
      end
      
      def display_list(type)
        setup_project(true)
        
        case type
        when :class
          items = run_verifier(Registry.all(:class, :module))
        when :methods
          items = Registry.all(:method).sort_by {|m| m.name.to_s }
          items = prune_method_listing(items)
        when :files
          items = options[:files]
        else 
          raise "Invalid list type #{type}"
        end

        options.update(:items => items, :template => :doc_server, 
                       :list_type => type, :type => :full_list)
        cache Templates::Engine.render(options)
      end
      
      def display_frame(path)
        setup_project
        
        if path && !path.empty?
          page_title = "Object: #{path}"
          main_url = "/docs/#{project}/#{path}"
        elsif options[:files].size > 0
          page_title = "File: #{options[:files].first}"
          main_url = url_for_file(options[:files].first)
        elsif !path || path.empty?
          page_title = "Documentation for #{project || Dir.pwd}"
          main_url = "/docs/#{project}/#{path}"
        end
        
        options.update(
          :project => project,
          :page_title => page_title,
          :main_url => main_url,
          :template => :doc_server,
          :type => :frames,
        )
        cache Templates::Engine.render(options)
      end
      
      def handle_docs(components)
        setup_yardopts

        if components.first == 'frames'
          components.shift
          display_frame(components.join('/'))
        elsif components.first =~ /^file:/
          display_file(components.join('/').sub(/^file:/, ''))
        else
          display_object(components.join('/').sub(':', '#').gsub('/', '::'))
        end
      end
      
      def handle_list(components)
        setup_yardopts

        type = components.first
        display_list(components.first.to_sym)
      end

      def handle_static
        path = File.cleanpath(request.path).gsub(%r{^(../)+}, '')
        path = File.join(YARD::TEMPLATE_ROOT, "default", "fulldoc", "html", path)
        if File.exist?(path)
          headers['Content-Type'] = 'text/' + request.path.split('.').last
          self.body = File.read(path)
        else
          self.status = 404
        end
      end
      
      def cache(data)
        self.body = data
      end
      
      private
      
      def setup_yardopts
        yardopts_file = File.join(project_path, CLI::Yardoc::DEFAULT_YARDOPTS_FILE)
        yardoc = CLI::Yardoc.new
        yardoc.options_file = yardopts_file
        yardoc.send(:optparse, *yardoc.yardopts)
        yardoc.send(:optparse, *yardoc.send(:support_rdoc_document_file!))
        yardoc.options.delete(:serializer)
        yardoc.options[:files].unshift(*Dir.glob(project_path + '/README*'))
        options.update(yardoc.options.to_hash)
      end
      
      def setup_project(force = false)
        self.serializer = DocServerSerializer.new(project)
        options[:serializer] = serializer
        load_yardoc(force)
        setup_yardopts
        { :@@mixed_into => Templates::Engine.template(:default, :module),
          :@@subclasses => Templates::Engine.template(:default, :class) }.each do |var, mod|
            mod.remove_class_variable(var) if mod.class_variable_defined?(var)
        end
        true
      end
      
      def load_yardoc(force)
        return unless @project_changed || !@first_load
        Registry.clear
        Registry.load(yardoc_file)
        Registry.load_all if force
        @first_load = true
      end
      
      def parse_uri
        components = request.path.gsub(%r{/+}, '/').split('/')[1..-1]
        command = components.shift
        last_project = project
        if single_project
          self.project = nil
          self.yardoc_file = projects.first.last
        else
          self.project = components.shift
          self.yardoc_file = projects.assoc(project)
        end
        
        @project_changed = project != last_project
        options[:project] = project
        options[:project_path] = project_path
        
        case command
        when 'docs'
          handle_docs(components)
        when 'list'
          handle_list(components) if components.first
        else
          handle_static
        end
      end
    end
  end
end