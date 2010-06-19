require 'webrick'

module YARD
  module Server
    class WebrickAdapter < WEBrick::HTTPServlet::AbstractServlet
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
      
      def self.start(projects, options = {}, server_options = {})
        server = WEBrick::HTTPServer.new(server_options)
        trap("INT") { server.shutdown }
        projects.each do |name, yardoc|
          PROJECT_COMMANDS.each do |uri, command|
            uri = uri.gsub('/:project', options[:single_project] ? '' : "/#{name}")
            opts = options.merge(
              :project => name,
              :yardoc_file => yardoc,
              :base_uri => uri
            )
            server.mount(uri, self, command, opts)
          end
        end
        
        ROOT_COMMANDS.each do |uri, command|
          opts = options.merge(:base_uri => uri)
          server.mount(uri, self, command, opts)
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
        server.mount('/', self, command, opts)
        
        server.start
      end
      
      def initialize(server, klass, *args)
        super
        @base = klass.new(*args)
      end
      
      def do_GET(request, response)
        status, headers, body = *@base.call(request)
        response.status = status
        response.body = body
        headers.each do |key, value|
          response[key] = value
        end
      end
    end
  end
end