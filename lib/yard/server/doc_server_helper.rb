module YARD
  module Server
    module DocServerHelper
      def url_for(obj, anchor = nil, relative = false)
        return '' if obj.nil?
        return "/#{obj}" if String === obj
        super(obj, anchor, false)
      end

      def url_for_file(filename, anchor = nil)
        "/#{base_path(router.docs_prefix)}/file/" + filename.sub(%r{^#{@library.source_path.to_s}/}, '') + 
          (anchor ? "##{anchor}" : "")
      end
      
      def base_path(path)
        path + (@single_library ? '' : "/#{@library}")
      end
      
      def router; @adapter.router end
    end
  end
end
