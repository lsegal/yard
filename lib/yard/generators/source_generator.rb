module YARD
  module Generators
    class SourceGenerator < Base
      def sections_for(object) 
        [:main] if object.source
      end
      
      protected
      
      def format_lines(object)
        i = -1
        object.source.split(/\n/).map { object.line + (i += 1) }.join("\n")
      end
      
      def format_code(object, show_lines = false)
        i = -1
        lines = object.source.split(/\n/)
        longestline = (object.line + lines.size).to_s.length
        lines.map do |line| 
          lineno = object.line + (i += 1)
          (" " * (longestline - lineno.to_s.length)) + lineno.to_s + "    " + line
        end.join("\n")
      end
    end
  end
end