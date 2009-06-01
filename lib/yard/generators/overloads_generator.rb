module YARD
  module Generators
    class OverloadsGenerator < Base
      before_generate :has_overloads?

      def sections_for(object)
        [
          :header,
          [G(MethodGenerator)]
        ]
      end

      protected

      def has_overloads?(object)
        object.tags(:overload).size > 1
      end
    end
  end
end
