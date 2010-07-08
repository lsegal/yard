require 'fileutils'

module YARD
  module Server
    module Commands
      class LibraryLoadError < RuntimeError; end
      class FileLoadError < RuntimeError; end
      class ObjectLoadError < RuntimeError; end
      class FinishRequest < RuntimeError; end
      
      class Base
        # @return [Hash] the options passed to the command's constructor
        attr_accessor :command_options
        
        # @return [String] the base URI for the command
        attr_accessor :base_path
        
        # @return [Request] request object
        attr_accessor :request
        
        # @return [String] the path after the command base URI
        attr_accessor :path

        # @return [Hash{String => String}] response headers
        attr_accessor :headers

        # @return [Numeric] status code
        attr_accessor :status

        # @return [String] the response body
        attr_accessor :body
        
        # @return [Adapter] the server adapter
        attr_accessor :server
        
        # @return [Boolean] whether to cache
        attr_accessor :caching

        def initialize(opts = {})
          opts.each do |key, value|
            send("#{key}=", value) if respond_to?("#{key}=")
          end
          self.command_options = opts
        end

        def call(request)
          self.request = request
          self.path = request.path[base_path.length..-1].sub(%r{^/+}, '')
          self.headers = {'Content-Type' => 'text/html'}
          self.body = ''
          self.status = 200
          begin; run; rescue FinishRequest; end
          [status, headers, body]
        end

        def run
          raise NotImplementedError
        end
        
        protected
        
        def cache(data)
          if caching && server.document_root
            path = File.join(server.document_root, request.path.sub(/\.html$/, '') + '.html')
            path = path.sub(%r{/\.html$}, '/index.html')
            FileUtils.mkdir_p(File.dirname(path))
            log.debug "Caching data to #{path}"
            File.open(path, 'wb') {|f| f.write(data) }
          end
          self.body = data
        end

        def render(object = nil)
          case object
          when CodeObjects::Base
            cache object.format(options)
          when nil
            cache Templates::Engine.render(options)
          else
            cache object
          end
        end

        def redirect(url)
          headers['Location'] = url
          self.status = 302
          raise FinishRequest
        end
      end
    end
  end
end
