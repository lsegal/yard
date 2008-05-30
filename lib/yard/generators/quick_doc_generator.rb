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
        when CodeObjects::NamespaceObject
          [
            :header,
            G(DeprecatedGenerator), 
            G(DocstringGenerator),
            G(MethodSummaryGenerator, :scope => :class, :visibility => :public),
            G(MethodSummaryGenerator, :scope => :instance, :visibility => :public)
          ]
        end
      end
    end
  end
end