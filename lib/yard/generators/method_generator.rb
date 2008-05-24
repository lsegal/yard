module YARD
  module Generators
    class MethodGenerator < Base
      def before_section(object)
        super
        return false unless current_object.is_a?(CodeObjects::MethodObject)
      end
      
      def sections_for(object) 
        [
          :header, 
          DeprecatedGenerator, 
          DocstringGenerator, 
          MethodSignatureGenerator, 
          TagsGenerator, 
          SourceGenerator
        ]
      end
    end
  end
end