require 'webrick'

module YARD
  module Server
    class WebrickAdapter < WEBrick::HTTPServlet::AbstractServlet
      def self.start(opts = {})
        YARD::Templates::Template.extra_includes << DocServerUrlHelper
        YARD::Templates::Engine.template_paths.push(File.dirname(__FILE__) + '/templates')
        server = WEBrick::HTTPServer.new(opts)
        trap("INT") { server.shutdown }
        server.mount("/", self)
        server.start
      end
      
      def initialize(*args)
        super
        @base = DocServer.new({'yard' => '.yardoc'}, true)
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