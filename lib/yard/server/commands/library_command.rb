module YARD
  module Server
    module Commands
      # This is the base command for all commands that deal directly with libraries.
      # Some commands do not, but most (like {DisplayObjectCommand}) do. If your
      # command deals with libraries directly, subclass this class instead.
      # See {Base} for notes on how to subclass a command.
      # 
      # @abstract
      class LibraryCommand < Base
        # @return [LibraryVersion] the object containing library information
        attr_accessor :library

        # @return [Hash{Symbol => Object}] default options for the library
        attr_accessor :options

        # @return [Serializers::Base] the serializer used to perform file linking
        attr_accessor :serializer

        # @return [Boolean] whether router should route for multiple libraries
        attr_accessor :single_library
        
        # @return [Boolean] whether to reparse data 
        attr_accessor :incremental

        # Needed to synchronize threads in {#setup_yardopts}
        # @private
        @@library_chdir_lock = Mutex.new
        
        def initialize(opts = {})
          super
          self.serializer = DocServerSerializer.new(self)
        end

        def call(request)
          self.request = request
          self.options = SymbolHash.new(false).update(
            :serialize => false,
            :serializer => serializer,
            :library => library,
            :adapter => adapter,
            :single_library => single_library,
            :markup => :rdoc,
            :format => :html
          )
          setup_library
          super
        rescue LibraryNotPreparedError
          not_prepared
        end
        
        protected
        
        # @group Helper Methods

        # Renders a specific object if provided, or a regular template rendering
        # if object is not provided.
        # 
        # @param [CodeObjects::Base, nil] object calls {CodeObjects::Base#format} if
        #   an object is provided, or {Templates::Engine.render} if object is nil. Both
        #   receive {#options} as an argument.
        # @return [String] the resulting output to display
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

        private
        
        # @endgroup

        def setup_library
          library.prepare! if request.xhr? && request.query['process']
          load_yardoc
          setup_yardopts
          true
        end

        def setup_yardopts
          @@library_chdir_lock.synchronize do
            Dir.chdir(library.source_path) do
              yardoc = CLI::Yardoc.new
              if incremental
                yardoc.run('-c', '-n', '--no-stats')
              else
                yardoc.parse_arguments
              end
              yardoc.options.delete(:serializer)
              yardoc.options[:files].unshift(*Dir.glob('README*'))
              options.update(yardoc.options.to_hash)
            end
          end
        end

        def load_yardoc
          raise LibraryNotPreparedError unless library.yardoc_file
          if @@last_yardoc == library.yardoc_file
            log.debug "Reusing yardoc file: #{library.yardoc_file}"
            return
          end
          Registry.clear
          Registry.load_yardoc(library.yardoc_file)
          @@last_yardoc = library.yardoc_file
        end
        
        def not_prepared
          self.caching = false
          options.update(:path => request.path, :template => :doc_server, :type => :processing)
          [302, {'Content-Type' => 'text/html'}, [render]]
        end
        
        # @private
        @@last_yardoc = nil
      end
    end
  end
end
