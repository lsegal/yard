module YARD
  module Generators::Helpers
    module FilterHelper
      def is_method?(object)
        object.is_a?(CodeObjects::MethodObject)
      end

      def is_namespace?(object)
        object.is_a?(CodeObjects::NamespaceObject)
      end
      
      def is_class?(object)
        object.is_a?(CodeObjects::ClassObject)
      end
      
      def is_module?(object)
        object.is_a?(CodeObjects::ModuleObject)
      end
    end
  end
end