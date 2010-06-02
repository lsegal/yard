module YARD
  module CLI
    # A local documentation server
    class Server < Base
      def run(*args)
        YARD::Server::WebrickAdapter.start(:Port => 8000)
      end
    end
  end
end