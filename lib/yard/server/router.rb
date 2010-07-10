module YARD
  module Server
    class Router
      include StaticCaching
      include Commands
      
      attr_accessor :request
      
      attr_accessor :adapter
      
      def initialize(adapter)
        self.adapter = adapter
      end
      
      def call(request)
        self.request = request
        if result = (check_static_cache || route)
          result
        else
          StaticFileCommand.new(adapter.options).call(request)
        end
      end

      def docs_prefix; 'docs' end
      def list_prefix; 'list' end
      def search_prefix; 'search' end
      
      # @return [Array(LibraryVersion, Array<String>)] the library followed
      #   by the rest of the path components in the request path. LibraryVersion
      #   will be nil if no matching library was found.
      def parse_library_from_path(paths)
        return [adapter.libraries.values.first.first, paths] if adapter.options[:single_library]
        library, paths = nil, paths.dup
        if libs = adapter.libraries[paths.first]
          paths.shift
          if library = libs.find {|l| l.version == paths.first }
            paths.shift
          else # use the last lib in the list
            library = libs.last
          end
        end
        [library, paths]
      end

      private
      
      def route
        path = request.path.gsub(%r{//+}, '/').gsub(%r{^/|/$}, '')
        return route_index if path.empty? || path == docs_prefix
        case path
        when /^(#{docs_prefix}|#{list_prefix}|#{search_prefix})(\/.*|$)/
          prefix = $1
          paths = $2.gsub(%r{^/|/$}, '').split('/')
          library, paths = *parse_library_from_path(paths)
          return unless library
          return case prefix
          when docs_prefix;   route_docs(library, paths)
          when list_prefix;   route_list(library, paths)
          when search_prefix; route_search(library, paths)
          end
        end
        nil
      end
      
      def route_docs(library, paths)
        return route_index if library.nil?
        case paths.first
        when "frames"
          paths.shift
          cmd = FramesCommand
        when "file"
          paths.shift
          cmd = DisplayFileCommand
        else
          cmd = DisplayObjectCommand
        end
        cmd = cmd.new(final_options(library, paths))
        cmd.call(request)
      end
      
      def route_index
        if adapter.options[:single_library]
          route_docs(adapter.libraries.values.first.first, [])
        else
          LibraryIndexCommand.new(adapter.options.merge(:path => '')).call(request)
        end
      end
      
      def route_list(library, paths)
        return if paths.empty?
        case paths.shift
        when "class";   cmd = ListClassesCommand
        when "methods"; cmd = ListMethodsCommand
        when "files";   cmd = ListFilesCommand
        else; return
        end
        cmd.new(final_options(library, paths)).call(request)
      end
      
      def route_search(library, paths)
        return unless paths.empty?
        SearchCommand.new(final_options(library, paths)).call(request)
      end
      
      def final_options(library, paths)
        adapter.options.merge(:library => library, :path => paths.join('/'))
      end
    end
  end
end
