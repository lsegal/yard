module YARD
  module Server
    module StaticCaching
      def check_static_cache(request, document_root)
        return nil unless document_root
        cache_path = File.join(document_root, request.path.sub(/\.html$/, '') + '.html')
        cache_path = cache_path.sub(%r{/\.html$}, '/index.html')
        if File.file?(cache_path)
          log.debug "Loading cache from disk: #{cache_path}"
          return [200, {'Content-Type' => 'text/html'}, File.read_binary(cache_path)]
        end
        nil
      end
    end
  end
end