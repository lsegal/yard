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
        mount_servlet(path, RackServlet, command, options)
      end
      
      def mount_servlet(path, servlet, *args)
        adapter = self
        url_map.map(path) { run servlet.new(adapter, *args) }
      end
      
      def start
        server.start
      end
    end
    
    class RackServlet
      include StaticCaching
      
      def initialize(adapter, command, options)
        @adapter = adapter
        @command_class = command
        @options = options
      end
      
      def call(env)
        request = Rack::Request.new(env)
        cache = check_static_cache(request, @adapter.document_root)
        cache ? cache : @command_class.new(@options).call(request) 
      end
    end
  end
end

# @private
class Rack::Request
  alias query params
  def xhr?; (env['HTTP_X_REQUESTED_WITH'] || "").downcase == "xmlhttprequest" end
end
