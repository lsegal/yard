module YARD
  module Templates::Helpers
    module UMLHelper
      def uml_visibility(object)
        case object.visibility
        when :public;    '+'
        when :protected; '#'
        when :private;   '-'
        end
      end
      
      def format_path(object)
        object.path.gsub('::', '_')
      end
      
      def h(text)
        text.to_s.gsub(/(\W)/, '\\\\\1')
      end
      
      def tidy(data)
        indent = 0
        data.split(/\n/).map do |line|
          line.gsub!(/^\s*/, '')
          next if line.empty?
          indent -= 1 if line =~ /^\s*\}\s*$/
          line = (' ' * (indent * 2)) + line
          indent += 1 if line =~ /\{\s*$/
          line
        end.compact.join("\n") + "\n"
      end
    end
  end
end