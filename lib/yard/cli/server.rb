module YARD
  module CLI
    # A local documentation server
    class Server < Command
      def description
        "Runs a local documentation server"
      end
      
      def run(*args)
        YARD::Server::WebrickAdapter.start(:Port => 8000)
      end
    end
  end
end