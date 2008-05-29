module YARD
  module Generators
    class QuickDocGenerator < Base
      def sections_for(object)
        case object
        when CodeObjects::MethodObject
          [
            :header, 
            G(DeprecatedGenerator), 
            G(DocstringGenerator), 
            G(MethodSignatureGenerator), 
            G(TagsGenerator), 
            G(SourceGenerator)
          ]
        end
      end
    end
  end
end