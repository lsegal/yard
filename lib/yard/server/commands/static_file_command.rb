module YARD
  module Server
    module Commands
      class StaticFileCommand < Base
        MIME_TYPES = {
          :js => 'text/javascript',
          :css => 'text/css',
          :png => 'image/png',
          :jpeg => 'image/jpeg',
          :jpg => 'image/jpg',
          :gif => 'image/gif',
          :bmp => 'image/bmp'
        }

        STATIC_PATHS = [
          File.join(YARD::TEMPLATE_ROOT, 'default', 'fulldoc', 'html'),
          File.join(File.dirname(__FILE__), '..', 'templates', 'default', 'fulldoc', 'html')
        ]
        
        def run
          path = File.cleanpath(request.path).gsub(%r{^(../)+}, '')
          STATIC_PATHS.each do |path_prefix|
            file = File.join(path_prefix, path)
            if File.exist?(file)
              ext = request.path.split('.').last
              headers['Content-Type'] = MIME_TYPES[ext.downcase.to_sym] || 'text/html'
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