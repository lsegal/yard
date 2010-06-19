module YARD
  module Server
    class DocServerSerializer < Serializers::FileSystemSerializer
      def initialize(project)
        super(:project => project, :extension => '')
      end
  
      def serialized_path(object)
        path = case object
        when CodeObjects::RootObject
          "toplevel"
        when CodeObjects::MethodObject
          super(object.namespace) + (object.scope == :instance ? ":" : ".") + object.name.to_s
        else
          super(object)
        end
        project_path = options[:project] ? '/' + options[:project] : ''
        return File.join('/docs' + project_path, path)
      end
    end
  end
end
