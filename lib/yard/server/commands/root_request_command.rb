module YARD
  module Server
    module Commands
      # Serves requests from the root of the server
      class RootRequestCommand < Base
        def run
          favicon?

          self.body = "Could not find: #{request.path}"
          self.status = 404
        end

        private

        # Return an empty favicon.ico if it does not exist so that
        # browsers don't complain.
        def favicon?
          return unless request.path == '/favicon.ico'
          self.headers['Content-Type'] = 'image/png'
          self.status = 200
          self.body = ''
          raise FinishRequest
        end
      end
    end
  end
end
