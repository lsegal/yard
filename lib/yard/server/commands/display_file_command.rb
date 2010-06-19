module YARD
  module Server
    module Commands
      class DisplayFileCommand < ProjectCommand
        def run
          ppath = project_path
          filename = File.cleanpath(File.join(project_path, path))
          raise FileLoadError if !File.file?(filename)
          if filename =~ /\.(jpe?g|gif|png|bmp)$/i
            headers['Content-Type'] = StaticFileCommand::MIME_TYPES[$1.downcase.to_sym] || 'text/html'
            render IO.read(filename)
          else
            options.update(:object => Registry.root, :type => :layout, :file => filename)
            render
          end
        end
      end
    end
  end
end