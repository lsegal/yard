module YARD
  module Server
    module Commands
      class ProjectCommand < Base
        # @return [String] the name of the project
        attr_accessor :project

        # @return [String] the path containing the yardoc file
        attr_accessor :project_path

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
          @gem = false
          self.serializer = DocServerSerializer.new(self)
          if yardoc_file == :gem
            initialize_gem
          else
            self.project_path = File.dirname(yardoc_file) 
          end
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
        
        def gem?
          @gem
        end

        private
        
        def initialize_gem
          @gem = true
          self.yardoc_file = Registry.yardoc_file_for_gem(project)
          return unless yardoc_file
          # Build gem docs on demand
          CLI::Gems.run(project) unless File.directory?(yardoc_file)
          spec = Gem.source_index.find_name(project).first
          self.project_path = spec.full_gem_path
        end

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