module YARD
  module Templates::Helpers
    module MethodHelper
      def format_args(object)
        unless object.parameters.empty?
          args = object.parameters.map {|n, v| v ? "#{n} = #{v}" : n.to_s }.join(", ")
          h("(#{args})")
        else
          ""
        end
      end
      
      def format_return_types(object)
        return unless object.has_tag?(:return) && object.tag(:return).types
        return if object.tag(:return).types.empty?
        format_types [object.tag(:return).types.first], false
      end
      
      def format_block(object)
        if object.has_tag?(:yieldparam)
          h "{|" + object.tags(:yieldparam).map {|t| t.name }.join(", ") + "| ... }"
        else
          ""
        end
      end
      
      def format_lines(object)
        return "" unless object.source
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
      
      def format_constant(value)
        sp = value.split("\n").last[/^(\s+)/, 1]
        num = sp ? sp.size : 0
        html_syntax_highlight value.gsub(/^\s{#{num}}/, '')
      end
    end
  end
end
