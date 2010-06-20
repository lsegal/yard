module YARD
  module Server
    class Adapter
      PROJECT_COMMANDS = {
        "/docs/:project/frames" => Commands::FramesCommand,
        "/docs/:project/file" => Commands::DisplayFileCommand,
        "/docs/:project" => Commands::DisplayObjectCommand,
        "/search/:project" => Commands::SearchCommand,
        "/list/:project/class" => Commands::ListClassesCommand,
        "/list/:project/methods" => Commands::ListMethodsCommand,
        "/list/:project/files" => Commands::ListFilesCommand
      }
      
      ROOT_COMMANDS = {
        "/css" => Commands::StaticFileCommand,
        "/js" => Commands::StaticFileCommand,
        "/images" => Commands::StaticFileCommand,
      }
      
      def initialize(projects, options = {}, server_options = {})
        options[:server] = self
        mount_project_commands(projects, options)
        mount_root_commands(projects, options)
      end
      
      def start
        raise NotImplementedError
      end
      
      def mount_command(path, command, options)
        raise NotImplementedError
      end
      
      def mount_servlet(path, servlet, *args)
        raise NotImplementedError
      end
      
      private
      
      def mount_project_commands(projects, options)
        projects.each do |name, yardoc|
          PROJECT_COMMANDS.each do |uri, command|
            uri = uri.gsub('/:project', options[:single_project] ? '' : "/#{name}")
            opts = options.merge(
              :project => name,
              :yardoc_file => yardoc,
              :base_uri => uri
            )
            mount_command(uri, command, opts)
          end
        end
      end
      
      def mount_root_commands(projects, options)
        ROOT_COMMANDS.each do |uri, command|
          opts = options.merge(:base_uri => uri)
          mount_command(uri, command, opts)
        end
        
        opts, command = {}, nil
        if options[:single_project]
          opts = options.merge(
            :project => projects.keys.first,
            :yardoc_file => projects.values.first,
            :base_uri => '/'
          )
          command = Commands::DisplayObjectCommand
        else
          opts = options.merge(:base_uri => '/', :projects => projects)
          command = Commands::ProjectIndexCommand
        end
        mount_command('/', command, opts)
      end
    end
  end
end