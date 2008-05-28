module YARD
  module Generators
    class MethodGenerator < Base
      before_generate :is_method?
      
      def sections_for(object) 
        [
          :header,
          [
            DeprecatedGenerator, 
            MethodSignatureGenerator, 
            DocstringGenerator, 
            TagsGenerator, 
            SourceGenerator
          ]
        ]
      end
    end
  end
end