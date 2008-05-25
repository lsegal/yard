module YARD
  module Generators
    class MethodGenerator < Base
      before_generate :is_method?
      
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
      
      protected
      
      def is_method?(object)
        object.is_a?(CodeObjects::MethodObject)
      end
    end
  end
end