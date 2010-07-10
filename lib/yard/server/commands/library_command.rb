module YARD
  module Server
    module Commands
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
        
        def initialize(opts = {})
          super
          self.serializer = DocServerSerializer.new(self)
        end

        def call(request)
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
          not_prepared(request)
        end

        private

        def setup_library
          library.prepare!
          load_yardoc
          setup_yardopts
          true
        end

        def setup_yardopts
          Dir.chdir(library.source_path)
          yardoc = CLI::Yardoc.new
          if incremental
            yardoc.run('--incremental', '-n', '--no-stats')
          else
            yardoc.parse_arguments
          end
          yardoc.options.delete(:serializer)
          yardoc.options[:files].unshift(*Dir.glob(library.source_path + '/README*'))
          options.update(yardoc.options.to_hash)
        end

        def load_yardoc
          if @@last_yardoc == library.yardoc_file
            log.debug "Reusing yardoc file: #{library.yardoc_file}"
            return
          end
          Registry.clear
          Registry.load_yardoc(library.yardoc_file)
          @@last_yardoc = library.yardoc_file
        end
        
        def not_prepared(request)
          self.caching = false
          options.update(:path => request.path, :template => :doc_server, :type => :processing)
          [302, {'Content-Type' => 'text/html'}, [render]]
        end
        
        @@last_yardoc = nil
      end
    end
  end
end