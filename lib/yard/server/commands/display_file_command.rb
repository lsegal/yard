module YARD
  module Server
    module Commands
      class DisplayFileCommand < LibraryCommand
        def run
          ppath = library.source_path
          filename = File.cleanpath(File.join(library.source_path, path))
          raise NotFoundError if !File.file?(filename)
          if filename =~ /\.(jpe?g|gif|png|bmp)$/i
            headers['Content-Type'] = StaticFileCommand::DefaultMimeTypes[$1.downcase] || 'text/html'
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