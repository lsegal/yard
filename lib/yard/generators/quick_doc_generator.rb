module YARD
  module Generators
    class QuickDocGenerator < Base
      def sections_for(object)
        case object
        when CodeObjects::MethodObject
          [:header, DeprecatedGenerator, DocstringGenerator, TagsGenerator, SourceGenerator]
        end
      end
    end
  end
end