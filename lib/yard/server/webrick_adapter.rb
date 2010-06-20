require 'webrick'

module YARD
  module Server
    class WebrickAdapter < Adapter
      attr_accessor :server
      
      def initialize(libraries, options = {}, server_options = {})
        server_options[:ServerType] = WEBrick::Daemon if server_options[:daemonize]
        self.server = WEBrick::HTTPServer.new(server_options)
        trap("INT") { server.shutdown }
        super
      end
      
      def mount_command(path, command, options)
        mount_servlet(path, WebrickServlet, command, options)
      end
      
      def mount_servlet(path, servlet, *args)
        server.mount(path, servlet, *args)
      end
    end

    class WebrickServlet < WEBrick::HTTPServlet::AbstractServlet
      attr_accessor :command
      
      def initialize(server, cmd_class, opts = {})
        super
        self.command = cmd_class.new(opts)
      end
      
      def do_GET(request, response)
        status, headers, body = *command.call(request)
        response.status = status
        response.body = body
        headers.each do |key, value|
          response[key] = value
        end
      end
    end
  end
end