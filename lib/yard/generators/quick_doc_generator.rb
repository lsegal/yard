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
        p "called a"
        "test"
      end
      
      def b(object)
        p "called b"
        "test2"
      end
    end
  end
end