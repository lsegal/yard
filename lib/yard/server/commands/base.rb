module YARD
  module Server
    module Commands
      class ProjectLoadError < RuntimeError; end
      class FileLoadError < RuntimeError; end
      class ObjectLoadError < RuntimeError; end
      class FinishRequest < RuntimeError; end
      
      class Base
        # @return [Hash] the options passed to the command's constructor
        attr_accessor :command_options
        
        # @return [String] the base URI for the command
        attr_accessor :base_uri
        
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

        def initialize(opts = {})
          opts.each do |key, value|
            send("#{key}=", value) if respond_to?("#{key}=")
          end
          self.command_options = opts
        end

        def call(request)
          self.request = request
          self.path = request.path[base_uri.length..-1].sub(%r{^/+}, '')
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
        
        def xhr?
          (request['X-Requested-With'] || "").downcase == 'xmlhttprequest'
        end
        
        def cache(data)
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
