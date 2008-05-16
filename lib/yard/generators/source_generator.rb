module YARD
  module Generators
    class SourceGenerator < Base
      def sections_for(object) 
        [:main] if object.source
      end
      
      protected
      
      def format_code(text)
        indent = text[/\n(\s*)/, 1].length - 2
        text.gsub(/^(\s){#{indent}}/, '')
      end
    end
  end
end