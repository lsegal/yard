module YARD
  module Server
    class DocServerSerializer < Serializers::FileSystemSerializer
      def initialize(command)
        super(:command => command, :extension => '')
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
        command = options[:command]
        project_path = command.single_project ? '' : '/' + command.project.to_s
        return File.join('/docs' + project_path, path)
      end
    end
  end
end
