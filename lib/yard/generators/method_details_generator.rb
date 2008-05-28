module YARD
  module Generators
    class MethodDetailsGenerator < MethodListingGenerator
      before_generate :is_namespace?
      
      def sections_for(object)
        [
          :header, 
          [ # with MethodObject
            :method_header,
            MethodGenerator,
          ]
        ]
      end
    end
  end
end