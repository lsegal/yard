module YARD
  module Generators
    class DocstringGenerator < Base
      def sections_for(object) 
        [:main] if object.docstring
      end
    end
  end
end