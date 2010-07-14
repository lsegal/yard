require 'webrick'

module YARD
  module Server
    class WebrickAdapter < Adapter
      def start
        server_options[:ServerType] = WEBrick::Daemon if server_options[:daemonize]
        server = WEBrick::HTTPServer.new(server_options)
        server.mount('/', WebrickServlet, self)
        trap("INT") { server.shutdown }
        server.start
      end
    end

    class WebrickServlet < WEBrick::HTTPServlet::AbstractServlet
      attr_accessor :adapter
      
      def initialize(server, adapter)
        super
        self.adapter = adapter
      end
      
      def do_GET(request, response)
        status, headers, body = *adapter.router.call(request)
        response.status = status
        response.body = body.is_a?(Array) ? body[0] : body
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
