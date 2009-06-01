module YARD
  module Generators
    class QuickDocGenerator < Base
      def sections_for(object)
        case object
        when CodeObjects::MethodObject
          [
            :header,
            [G(MethodGenerator)]
          ]
        when CodeObjects::NamespaceObject
          [
            :header, 
            [
              G(DeprecatedGenerator), 
              G(DocstringGenerator),
              G(AttributesGenerator),
              G(MethodSummaryGenerator, :scope => [:class, :instance], :visibility => :public)
            ]
          ]
        end
      end
    end
  end
end
