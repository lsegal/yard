module YARD
  module Server
    module Commands
      class DisplayObjectCommand < LibraryCommand
        def run
          return index if path.empty?
          
          object = Registry.at(object_path)
          options.update(:type => :layout)
          render(object)
        end
        
        def index
          Registry.load_all

          title = options[:title]
          unless title
            title = "Documentation for #{library.name} #{library.version ? '(' + library.version + ')' : ''}"
          end
          options.update(
            :object => '_index.html',
            :objects => Registry.all(:module, :class),
            :title => title,
            :type => :layout
          )
          render
        end
        
        private
        
        def object_path
          return @object_path if @object_path
          if path == "toplevel"
            @object_path = :root
          else
            @object_path = path.sub(':', '#').gsub('/', '::').sub(/^toplevel\b/, '').sub(/\.html$/, '')
          end
        end
      end
    end
  end
end
