module YARD
  module Server
    module Commands
      class ProjectLoadError < RuntimeError; end
      class FileLoadError < RuntimeError; end
      class ObjectLoadError < RuntimeError; end
      class FinishRequest < RuntimeError; end
      
      class Base
        # @return [Request] request object
        attr_accessor :request
        
        # @return [String] the path after the command base URI
        attr_accessor :path

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
        
        # @return [String] the base URI for the command
        attr_accessor :base_uri

        def initialize(project, yardoc, base_uri, single = false)
          self.project = project
          self.yardoc_file = yardoc
          self.base_uri = base_uri
          self.single_project = single
          self.serializer = DocServerSerializer.new(self)
        end

        def call(request)
          self.options = SymbolHash.new(false).update(
            :serialize => false,
            :serializer => serializer,
            :project => project,
            :project_path => project_path,
            :single_project => single_project,
            :markup => :rdoc,
            :format => :html
          )
          self.request = request
          self.path = request.path[base_uri.length..-1].sub(%r{^/+}, '')
          self.headers = {'Content-Type' => 'text/html'}
          self.body = ''
          self.status = 200

          setup_project
          begin; run; rescue FinishRequest; end
          [status, headers, body]
        end

        undef project_path
        def project_path
          return '' unless yardoc_file
          File.dirname(yardoc_file)
        end
        
        def run
          raise NotImplementedError
        end
        
        protected
        
        def xhr?
          (request['X-Requested-With'] || "").downcase == 'xmlhttprequest'
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

        def setup_project
          return unless yardoc_file
          load_yardoc
          setup_yardopts
          { :@@mixed_into => Templates::Engine.template(:default, :module),
            :@@subclasses => Templates::Engine.template(:default, :class) }.each do |var, mod|
              mod.remove_class_variable(var) if mod.class_variable_defined?(var)
          end
          true
        end

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

        def load_yardoc
          Registry.clear
          Registry.load(yardoc_file)
        end
      end
    end
  end
end
