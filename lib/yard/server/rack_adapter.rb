require 'rack'

module YARD
  module Server
    class RackAdapter < Adapter
      attr_accessor :server
      attr_accessor :url_map
      
      def initialize(libraries, options = {}, server_options = {})
        self.url_map = Rack::Builder.new
        self.server = Rack::Server.new(server_options)
        server.instance_variable_set("@app", url_map)
        trap("INT") { server.shutdown }
        super
      end
      
      def mount_command(path, command, options)
        url_map.map(path) do
          run lambda {|env| command.new(options).call(Rack::Request.new(env)) }
        end
      end
      
      def mount_servlet(path, servlet, *args)
        url_map.map(path) do
          run lambda {|env| servlet.new(*args).call(env) }
        end
      end
      
      def start
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
