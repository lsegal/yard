require 'rack'
require 'webrick/httputils'

module YARD
  module Server
    class RackMiddleware
      def initialize(app, opts = {})
        args = [opts[:libraries] || {}, opts[:options] || {}, opts[:server_options] || {}]
        @app = app
        @adapter = RackAdapter.new(*args)
      end
      
      def call(env)
        status, headers, body = *@adapter.call(env)
        if status == 404
          @app.call(env)
        else
          [status, headers, body]
        end
      end
    end
    
    class RackAdapter < Adapter
      include WEBrick::HTTPUtils
      
      def call(env)
        request = Rack::Request.new(env)
        request.path_info = unescape(request.path_info) # unescape things like %3F
        router.call(request)
      end
      
      def start
        server = Rack::Server.new(server_options)
        server.instance_variable_set("@app", self)
        print_start_message(server)
        server.start
      end
      
      private
      
      def print_start_message(server)
        opts = server.default_options.merge(server.options)
        puts ">> YARD #{YARD::VERSION} documentation server at http://#{opts[:Host]}:#{opts[:Port]}"

        # Only happens for Mongrel
        return unless server.server.to_s == "Rack::Handler::Mongrel"
        puts ">> #{server.server.class_name} web server (running on Rack)"
        puts ">> Listening on #{opts[:Host]}:#{opts[:Port]}, CTRL+C to stop"
      end
    end
  end
end

# @private
class Rack::Request
  alias query params
  def xhr?; (env['HTTP_X_REQUESTED_WITH'] || "").downcase == "xmlhttprequest" end
end
