module YARD
  module Server
    class FinishRequest < RuntimeError; end
    class NotFoundError < RuntimeError; end

    class Adapter
      # @return [String] the location where static files are located, if any
      attr_accessor :document_root
      
      attr_accessor :libraries
      
      attr_accessor :options
      
      attr_accessor :server_options
      
      attr_accessor :router

      def self.setup
        Templates::Template.extra_includes |= [YARD::Server::DocServerHelper]
        Templates::Engine.template_paths |= [File.dirname(__FILE__) + '/templates']
      end

      def self.shutdown
        Templates::Template.extra_includes -= [YARD::Server::DocServerHelper]
        Templates::Engine.template_paths -= [File.dirname(__FILE__) + '/templates']
      end
      
      def initialize(libs, opts = {}, server_opts = {})
        self.class.setup
        self.libraries = libs
        self.options = opts
        self.server_options = server_opts
        self.document_root = server_options[:DocumentRoot]
        self.router = (options[:router] || Router).new(self)
        options[:adapter] = self
        log.debug "Serving libraries using #{self.class}: #{libraries.keys.join(', ')}"
        log.debug "Caching on" if options[:caching]
        log.debug "Document root: #{document_root}" if document_root
      end
      
      def add_library(library)
        libraries[library.name] ||= []
        libraries[library.name] |= [library]
      end
      
      def start
        raise NotImplementedError
      end
    end
  end
end