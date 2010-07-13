require 'fileutils'

module YARD
  module Server
    module Commands
      class Base
        # @return [Hash] the options passed to the command's constructor
        attr_accessor :command_options
        
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
        attr_accessor :adapter
        
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
          self.path ||= request.path[1..-1]
          self.headers = {'Content-Type' => 'text/html'}
          self.body = ''
          self.status = 200
          begin
            run
          rescue FinishRequest
          rescue NotFoundError => e
            self.body = e.message if e.message
            self.status = 404
          end
          not_found if status == 404
          [status, headers, body.is_a?(Array) ? body : [body]]
        end

        def run
          raise NotImplementedError
        end
        
        def not_found
          return unless body.empty?
          self.body = "Not found: #{request.path}"
          self.headers['Content-Type'] = 'text/plain'
          self.headers['X-Cascade'] = 'pass'
        end
        
        protected
        
        def cache(data)
          if caching && adapter.document_root
            path = File.join(adapter.document_root, request.path.sub(/\.html$/, '') + '.html')
            path = path.sub(%r{/\.html$}, '.html')
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
