module YARD
  module Server
    module Commands
      class LibraryCommand < Base
        # @return [LibraryVersion] the object containing library information
        attr_accessor :library

        # @return [String] the path containing the yardoc file
        attr_accessor :library_path

        # @return [String] the yardoc to use for lookups
        attr_accessor :yardoc_file

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
          @gem = false
          self.serializer = DocServerSerializer.new(self)
          if library.yardoc_file == :gem
            initialize_gem
          else
            self.yardoc_file = library.yardoc_file
            self.library_path = File.dirname(yardoc_file) 
          end
        end

        def call(request)
          self.options = SymbolHash.new(false).update(
            :serialize => false,
            :serializer => serializer,
            :library => library,
            :library_path => library_path,
            :single_library => single_library,
            :markup => :rdoc,
            :format => :html
          )
          setup_library
          super
        end

        private
        
        def initialize_gem
          require 'rubygems'
          @gem = true
          ver = library.version ? "= #{library.version}" : ">= 0"
          self.yardoc_file = Registry.yardoc_file_for_gem(library.name, ver)
          unless yardoc_file && File.directory?(yardoc_file)
            # Build gem docs on demand
            log.debug "Building gem docs for #{library.to_s(false)}"
            CLI::Gems.run(library.name, ver)
            self.yardoc_file = Registry.yardoc_file_for_gem(library.name, ver)
          end
          spec = Gem.source_index.find_name(library.name, ver).first
          self.library_path = spec.full_gem_path
        end

        def setup_library
          return unless yardoc_file
          load_yardoc
          setup_yardopts
          true
        end

        def setup_yardopts
          return unless @library_changed || !@first_load
          Dir.chdir(library_path)
          yardoc = CLI::Yardoc.new
          if incremental
            yardoc.run('--incremental', '-n', '--no-stats')
          else
            yardoc.parse_arguments
          end
          yardoc.options.delete(:serializer)
          yardoc.options[:files].unshift(*Dir.glob(library_path + '/README*'))
          options.update(yardoc.options.to_hash)
        end

        def load_yardoc
          if @@last_yardoc == yardoc_file
            log.debug "Reusing yardoc file: #{yardoc_file}"
            return
          end
          Registry.clear
          Registry.load(yardoc_file)
          @@last_yardoc = yardoc_file
        end
        
        @@last_yardoc = nil
      end
    end
  end
end