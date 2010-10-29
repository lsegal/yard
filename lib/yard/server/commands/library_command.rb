module YARD
  module Server
    module Commands
      class LibraryCommand < Base

        #Seems the threads step on one another in setup_yardopts
        @@library_chdir_lock = Mutex.new

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

        private

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
              yardoc.options[:files].unshift(*Dir.glob(library.source_path + '/README*'))
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
        
        @@last_yardoc = nil
      end
    end
  end
end
