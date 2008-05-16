module YARD
  module Generators
    class MethodSignatureGenerator < Base
      def sections_for(object) 
        [:main] if object.docstring
      end
      
      protected
      
      def format_signature(text)
        indent = text[/\n(\s*)/, 1].length - 2
        text.gsub(/^(\s){#{indent}}/, '')
      end
    end
  end
end