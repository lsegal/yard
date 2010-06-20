module YARD
  module Server
    class Adapter
      PROJECT_COMMANDS = {
        "/docs/:library/frames" => Commands::FramesCommand,
        "/docs/:library/file" => Commands::DisplayFileCommand,
        "/docs/:library" => Commands::DisplayObjectCommand,
        "/search/:library" => Commands::SearchCommand,
        "/list/:library/class" => Commands::ListClassesCommand,
        "/list/:library/methods" => Commands::ListMethodsCommand,
        "/list/:library/files" => Commands::ListFilesCommand
      }
      
      ROOT_COMMANDS = {
        "/css" => Commands::StaticFileCommand,
        "/js" => Commands::StaticFileCommand,
        "/images" => Commands::StaticFileCommand,
      }
      
      def initialize(libraries, options = {}, server_options = {})
        options[:server] = self
        mount_library_commands(libraries, options)
        mount_root_commands(libraries, options)
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
      
      def mount_library_commands(libraries, options)
        libraries.each do |name, yardoc|
          PROJECT_COMMANDS.each do |uri, command|
            uri = uri.gsub('/:library', options[:single_library] ? '' : "/#{name}")
            opts = options.merge(
              :library => name,
              :yardoc_file => yardoc,
              :base_uri => uri
            )
            mount_command(uri, command, opts)
          end
        end
      end
      
      def mount_root_commands(libraries, options)
        ROOT_COMMANDS.each do |uri, command|
          opts = options.merge(:base_uri => uri)
          mount_command(uri, command, opts)
        end
        
        opts, command = {}, nil
        if options[:single_library]
          opts = options.merge(
            :library => libraries.keys.first,
            :yardoc_file => libraries.values.first,
            :base_uri => '/'
          )
          command = Commands::DisplayObjectCommand
        else
          opts = options.merge(:base_uri => '/', :libraries => libraries)
          command = Commands::LibraryIndexCommand
        end
        mount_command('/', command, opts)
      end
    end
  end
end