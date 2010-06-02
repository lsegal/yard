module YARD
  module Server
    class DocServerSerializer < Serializers::FileSystemSerializer
      def initialize(project)
        super(:project => project, :extension => '')
      end
  
      def serialized_path(object)
        path = object.root? ? "toplevel" : super(object)
        project_path = options[:project] ? '/' + options[:project] : ''
        return File.join('/docs' + project_path, path)
      end
    end
  end
end
