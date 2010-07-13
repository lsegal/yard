require 'webrick/httputils'

module YARD
  module Server
    module Commands
      class StaticFileCommand < Base
        include WEBrick::HTTPUtils

        DefaultMimeTypes['js'] = 'text/javascript'

        STATIC_PATHS = [
          File.join(YARD::TEMPLATE_ROOT, 'default', 'fulldoc', 'html'),
          File.join(File.dirname(__FILE__), '..', 'templates', 'default', 'fulldoc', 'html')
        ]
        
        def run
          path = File.cleanpath(request.path).gsub(%r{^(../)+}, '')
          ([adapter.document_root] + STATIC_PATHS).compact.each do |path_prefix|
            file = File.join(path_prefix, path)
            if File.exist?(file)
              ext = "." + (request.path[/\.(\w+)$/, 1] || "html")
              headers['Content-Type'] = mime_type(ext, DefaultMimeTypes)
              self.body = File.read(file)
              return
            end
          end
          self.status = 404
        end
      end
    end
  end
end