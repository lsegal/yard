module YARD
  module Server
    module DocServerHelper
      def url_for(obj, anchor = nil, relative = false)
        return "/#{obj}" if String === obj
        super(obj, anchor, false).gsub('?', '%3F')
      end

      def url_for_file(filename, anchor = nil)
        "/#{base_path('docs')}/file/" + filename.sub(%r{^#{@project_path.to_s}/}, '') + 
          (anchor ? "##{anchor}" : "")
      end
      
      def base_path(path)
        path + (@single_project ? '' : "/#{@project}")
      end
    end
  end
end
