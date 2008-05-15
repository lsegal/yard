module YARD
  module Generators
    class QuickDocGenerator < Base
      def sections_for(object)
        case object
        when CodeObjects::MethodObject
          [:a, :b]
        end
      end
      
      def a(object)
        "test"
      end
      
      def b(object)
        "test2"
      end
    end
  end
end