module YARD
  module Generators
    class DocstringGenerator < Base
      before_section :main, :has_docstring?
      
      def sections_for(object) [:main] end
      
      protected
      
      def has_docstring?
        !current_object.docstring.empty?
      end
    end
  end
end