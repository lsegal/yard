module YARD
  module Server
    class ProjectLoadError < RuntimeError; end
    class FileLoadError < RuntimeError; end
    class ObjectLoadError < RuntimeError; end
    class FinishRequest < RuntimeError; end
    
    class DocServer
      include Templates::Helpers::BaseHelper
      include Templates::Helpers::ModuleHelper
      include DocServerUrlHelper
      
      class << self
        attr_accessor :static_paths
        attr_accessor :mime_types
      end
      
      self.static_paths = [
        File.join(YARD::TEMPLATE_ROOT, 'default', 'fulldoc', 'html'),
        File.join(File.dirname(__FILE__), 'templates', 'default', 'fulldoc', 'html')
      ]
      
      self.mime_types = {
        :js => 'text/javascript',
        :css => 'text/css',
        :png => 'image/png',
        :jpeg => 'image/jpeg',
        :jpg => 'image/jpg',
        :gif => 'image/gif',
        :bmp => 'image/bmp'
      }
      
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
        
        begin
          parse_uri
        rescue FinishRequest
        end
        
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
        render(object)
      end
      
      def display_file(file)
        setup_project

        ppath = project_path
        filename = File.cleanpath(File.join(project_path, file))
        raise FileLoadError if !File.file?(filename)
        if filename =~ /\.(jpe?g|gif|png|bmp)$/i
          headers['Content-Type'] = self.class.mime_types[$1.downcase.to_sym] || 'text/html'
          render IO.read(filename)
        else
          options.update(:object => Registry.root, :type => :layout, :file => filename)
          render
        end
      end
      
      def display_index
        setup_project(true)

        title = "Documentation for Project #{project || File.basename(Dir.pwd)}"
        title = options[:title] || title
        options.update(
          :object => '_index.html',
          :objects => Registry.all(:module, :class),
          :title => title,
          :type => :layout
        )
        render
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
        render
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
          :page_title => page_title,
          :main_url => main_url,
          :template => :doc_server,
          :type => :frames
        )
        render
      end
      
      def display_project_list
        if single_project
          self.project = projects.first.first
          self.yardoc_file = projects.first.last
          return(display_index)
        end
        
        
        options.update(
          :projects => projects,
          :template => :doc_server,
          :type => :project_list
        )
        render
      end
      
      def handle_docs(components)
        setup_yardopts

        if components.first == 'frames'
          components.shift
          display_frame(components.join('/'))
        elsif components.first =~ /^file:/
          display_file(components.join('/').sub(/^file:/, ''))
        elsif components.first && !components.first.empty?
          display_object(components.join('/').sub(':', '#').gsub('/', '::'))
        else
          display_index
        end
      end
      
      def handle_list(components)
        setup_yardopts

        type = components.first
        display_list(components.first.to_sym)
      end
      
      def handle_search
        setup_yardopts
        setup_project(true)
        search = request.query['q']
        redirect("/docs/#{project}") if search =~ /\A\s*\Z/
        if found = Registry.at(search)
          redirect(serializer.serialized_path(found))
        end

        splitquery = search.split(/\s+/).map {|c| c.downcase }.reject {|m| m.empty? }
        results = Registry.all.select {|o|
            o.path.downcase.include?(search.downcase)
          }.reject {|o|
            name = (o.type == :method ? o.name(true) : o.name).to_s.downcase
            !name.include?(search.downcase) ||
            case o.type
            when :method
              !(search =~ /[#.]/) && search.include?("::")
            when :class, :module, :constant, :class_variable
              search =~ /[#.]/
            end 
          }.sort_by {|o|
            name = (o.type == :method ? o.name(true) : o.name).to_s
            name.length.to_f / search.length.to_f
          }
        visible_results = results[0, 10]

        if request.header['X-Requested-With'] == 'XmlHttpRequest'
          self.headers['Content-Type'] = 'text/plain'
          self.body = visible_results.map {|o| 
            [(o.type == :method ? o.name(true) : o.name).to_s,
             o.path,
             o.namespace.root? ? '' : o.namespace.path,
             serializer.serialized_path(o)
            ].join(",")
          }.join("\n")
        else
          options.update(
            :visible_results => visible_results,
            :query => search,
            :results => results,
            :template => :doc_server,
            :type => :search
          )
          self.body = Templates::Engine.render(options)
        end
      end

      def handle_static
        path = File.cleanpath(request.path).gsub(%r{^(../)+}, '')
        self.class.static_paths.each do |path_prefix|
          file = File.join(path_prefix, path)
          if File.exist?(file)
            ext = request.path.split('.').last
            headers['Content-Type'] = self.class.mime_types[ext.downcase.to_sym] || 'text/html'
            self.body = File.read(file)
            return
          end
        end
        self.status = 404
      end
      
      def cache(data)
        self.body = data
      end
      
      def render(object = nil)
        case object
        when CodeObjects::Base
          cache object.format(options)
        when nil
          cache Templates::Engine.render(options)
        else
          cache object
        end
      end

      def redirect(url)
        headers['Location'] = url
        self.status = 302
        raise FinishRequest
      end
      
      private
      
      def setup_yardopts
        return unless @project_changed || !@first_load
        yardopts_file = File.join(project_path, CLI::Yardoc::DEFAULT_YARDOPTS_FILE)
        yardoc = CLI::Yardoc.new
        yardoc.options_file = yardopts_file
        yardoc.parse_arguments
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
        return display_project_list if components.nil? || components.empty?
        
        command = components.shift
        last_project = project
        if single_project
          self.project = projects.first.first
          self.yardoc_file = projects.first.last
          components.shift if components.first == project
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
        when 'search'
          handle_search
        else
          handle_static
        end
      end
    end
  end
end