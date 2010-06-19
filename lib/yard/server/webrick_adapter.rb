require 'webrick'

module YARD
  module Server
    class WebrickAdapter < WEBrick::HTTPServlet::AbstractServlet
      COMMANDS = {
        "/docs/:project/frames" => Commands::FramesCommand,
        "/docs/:project/file" => Commands::DisplayFileCommand,
        "/docs/:project" => Commands::DisplayObjectCommand,
        "/search/:project" => Commands::SearchCommand,
        "/list/:project/class" => Commands::ListClassesCommand,
        "/list/:project/methods" => Commands::ListMethodsCommand,
        "/list/:project/files" => Commands::ListFilesCommand
      }
      
      def self.start(projects, options = {}, server_options = {})
        server = WEBrick::HTTPServer.new(server_options)
        trap("INT") { server.shutdown }
        projects.each do |name, yardoc|
          COMMANDS.each do |uri, command|
            uri = uri.gsub('/:project', '') if options[:single_project]
            uri = uri.gsub('/:project', "/#{name}")
            server.mount(uri, self, command, name, yardoc, uri, options)
          end
        end
        
        server.mount('/', self, Commands::RootCommand, projects, '/', options)
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