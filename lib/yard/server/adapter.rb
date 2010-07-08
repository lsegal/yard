module YARD
  module Server
    class Adapter
      # @return [String] the location where static files are located, if any
      attr_accessor :document_root
      
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
        self.document_root = server_options[:DocumentRoot]
        options[:server] = self
        mount_library_commands(libraries, options)
        mount_root_commands(libraries, options)
        log.debug "Serving libraries using #{self.class}: #{libraries.keys.join(', ')}"
        log.debug "Caching on" if options[:caching]
        log.debug "Document root: #{document_root}" if document_root
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
      
      def mount_library(library, options)
        PROJECT_COMMANDS.each do |uri, command|
          uri = uri.gsub('/:library', options[:single_library] ? '' : "/#{library}")
          opts = options.merge(
            :library => library,
            :base_path => uri
          )
          mount_command(uri, command, opts)
        end
      end
      
      private
      
      def mount_library_commands(libraries, options)
        libraries.each do |name, library_versions|
          library_versions.each do |library|
            mount_library(library, options)
          end
        end
      end
      
      def mount_root_commands(libraries, options)
        ROOT_COMMANDS.each do |uri, command|
          opts = options.merge(:base_path => uri)
          mount_command(uri, command, opts)
        end
        
        opts, command = {}, nil
        if options[:single_library]
          opts = options.merge(
            :library => libraries.values.first.first,
            :base_path => '/'
          )
          command = Commands::DisplayObjectCommand
        else
          opts = options.merge(:base_path => '/', :libraries => libraries)
          command = Commands::LibraryIndexCommand
        end
        mount_command('/', command, opts)
      end
    end
  end
end