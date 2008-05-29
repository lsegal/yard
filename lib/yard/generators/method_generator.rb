module YARD
  module Generators
    class MethodGenerator < Base
      before_generate :is_method?
      
      def sections_for(object) 
        [
          :header,
          [
            G(DeprecatedGenerator), 
            G(MethodSignatureGenerator), 
            G(DocstringGenerator), 
            G(TagsGenerator), 
            G(SourceGenerator)
          ]
        ]
      end
    end
  end
end