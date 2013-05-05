require 'rack'

module YARD
  module Server
    class Authenticator

      # Set up authentication.  If both arguments expected_username and expected_password are nil, then
      # don't require authentication.
      # @param [String] expected_username the user name that users are expected to match. If nil, ignore
      # @param [String] expected_password the password that users are expected to match. if nil, ignore
      # @param [String] realm the name of the server to be shown in the login dialog.
      def initialize(expected_username, expected_password, realm)
        @username = expected_username
        @password = expected_password
        @realm    = realm
      end

      # Protect the YARD server
      # @param [Rack::Server] rack_server the YARD documentation Rack server to be protected by authentication
      # @return [Rack::Auth::Basic] the authentication object protecting the YARD server
      def authorized_server(rack_server)
        protected_server       = Rack::Auth::Basic.new(rack_server) do |username, password|
          credentials_match?(password, username)
        end
        protected_server.realm = @realm
        protected_server
      end

      # Answers whether the supplied credentials match
      # @param [String] password the supplied password.  If nil, then the password is not checked
      # @param [String] username the supplied user name.  If nil, then the user name is not checked
      # @return [Boolean] true if the supplied credential both match the expected credentials; else false
      def credentials_match?(password, username)
        username_match = @username.nil? || @username == username
        password_match = @password.nil? || @password == password
        username_match && password_match
      end

    end
  end
end
