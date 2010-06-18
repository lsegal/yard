module YARD
  module Server
    module DocServerUrlHelper
      def url_for(obj, anchor = nil, relative = false)
        return "/#{obj}" if String === obj
        super(obj, anchor, false).gsub('?', '%3F')
      end

      def url_for_file(filename, anchor = nil)
        "/docs/#{@project}/file:" + filename.sub(%r{^#{@project_path.to_s}/}, '') + 
          (anchor ? "##{anchor}" : "")
      end
    end
  end
end
