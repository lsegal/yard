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
        server.mount(path, servlet, self, *args)
      end
      
      def start
        server.start
      end
    end

    class WebrickServlet < WEBrick::HTTPServlet::AbstractServlet
      include StaticCaching
      
      attr_accessor :command
      attr_accessor :adapter
      
      def initialize(server, adapter, cmd_class, opts = {})
        super
        self.adapter = adapter
        self.command = cmd_class.new(opts)
      end
      
      def do_GET(request, response)
        if cache = check_static_cache(request, adapter.document_root)
          status, headers, body = *cache
        else
          status, headers, body = *command.call(request)
        end

        response.status = status
        response.body = body
        headers.each do |key, value|
          response[key] = value
        end
      end
    end
  end
end

# @private
class WEBrick::HTTPRequest
  def xhr?; (self['X-Requested-With'] || "").downcase == 'xmlhttprequest' end
end
