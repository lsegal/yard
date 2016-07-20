require 'webrick/httputils'

module YARD
  module Server
    module Commands
      # Include this module to get access to {#static_template_file?}
      # and {favicon?} helpers.
      module StaticFileHelpers
        include WEBrick::HTTPUtils
        
        # Serves an empty favicon.
        # @raise [FinishRequest] finalizes an empty body if the path matches
        #   /favicon.ico so browsers don't complain.
        def favicon?
          return unless request.path == '/favicon.ico'
          self.headers['Content-Type'] = 'image/png'
          self.status = 200
          self.body = ''
          raise FinishRequest
        end

        # Attempts to route a path to a static template file.
        #
        # @raise [FinishRequest] if a file was found and served
        # @return [void]
        def static_template_file?
          # these consts were defined in StaticFileCommand originally 
          static_paths = StaticFileCommand::STATIC_PATHS
          default_mime_types = StaticFileCommand::DefaultMimeTypes

          assets_template = Templates::Engine.template(:default, :fulldoc, :html)

          file = nil
          ([adapter.document_root] + static_paths.reverse).compact.each do |path_prefix|
            file = File.join(path_prefix, path)
            break if File.exist?(file)
            file = nil
          end

          # Search in default/fulldoc/html template if nothing in static asset paths
          file ||= assets_template.find_file(path)

          if file
            ext = "." + (path[/\.(\w+)$/, 1] || "html")
            headers['Content-Type'] = mime_type(ext, default_mime_types)
            self.body = File.read(file)
            raise FinishRequest
          end
        end
      end
    end
  end
end
