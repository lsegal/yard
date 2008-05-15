module YARD
  module Generators
    class QuickDocGenerator < Base
      def sections_for(object)
        case object
        when CodeObjects::MethodObject
          [DeprecatedGenerator, TagsGenerator]
        end
      end
    end
  end
end