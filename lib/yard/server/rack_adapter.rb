require 'rack'

module YARD
  module Server
    class RackMiddleware
      def initialize(app, opts = {})
        args = [opts[:libraries] || {}, opts[:options] || {}, opts[:server_options] || {}]
        @app = RackAdapter.new(*args)
      end
      
      def call(env) @app.call(env) end
    end
    
    class RackAdapter < Adapter
      def call(env)
        router.call(Rack::Request.new(env))
      end
      
      def start
        server = Rack::Server.new(server_options)
        server.instance_variable_set("@app", self)
        trap("INT") { server.shutdown }
        server.start
      end
    end
  end
end

# @private
class Rack::Request
  alias query params
  def xhr?; (env['HTTP_X_REQUESTED_WITH'] || "").downcase == "xmlhttprequest" end
end
