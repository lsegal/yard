module YARD
  module Server
    class Router
      include StaticCaching
      include Commands
      
      DOCS_PREFIX = 'docs'
      LIST_PREFIX = 'list'
      SEARCH_PREFIX = 'search'
      
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
        paths = request.path[1..-1].gsub(%r{//+}, '/').sub(%r{/$}, '').split('/')
        return route_index if paths.empty? || paths == [DOCS_PREFIX]
        prefix = paths.shift
        case prefix
        when DOCS_PREFIX, LIST_PREFIX, SEARCH_PREFIX
          library, paths = *parse_library_from_path(paths)
          return unless library
          return case prefix
          when DOCS_PREFIX;   route_docs(library, paths)
          when LIST_PREFIX;   route_list(library, paths)
          when SEARCH_PREFIX; route_search(library, paths)
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
