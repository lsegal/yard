module YARD
  module Generators
    class SourceGenerator < Base
      def sections_for(object) 
        [:main] if object.source
      end
      
      protected
      
      def format_code(text)
        text
      end
    end
  end
end