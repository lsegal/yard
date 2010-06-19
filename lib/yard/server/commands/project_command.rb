module YARD
  module Server
    module Commands
      class ProjectCommand < Base
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
        
        # @return [Boolean] whether to cache
        attr_accessor :caching
        
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
            :project => project,
            :project_path => project_path,
            :single_project => single_project,
            :markup => :rdoc,
            :format => :html
          )
          setup_project
          super
        end
        
        undef project_path
        def project_path
          return '' unless yardoc_file
          File.dirname(yardoc_file)
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
          Dir.chdir(project_path)
          yardoc = CLI::Yardoc.new
          if incremental
            yardoc.run('--incremental', '-n')
          else
            yardoc.parse_arguments
          end
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