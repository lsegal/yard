module YARD
  module Generators::Helpers
    module MethodHelper
      protected
      
      def format_def(object)
        h(object.signature.gsub(/^def\s*(?:.+?(?:\.|::)\s*)?/, ''))
      end
      
      def format_return_types(object)
        if object.has_tag?(:return) && !object.tag(:return).types.empty?
          format_types [object.tag(:return).types.first], false
        else
          "Object"
        end
      end
      
      def format_block(object)
        if object.has_tag?(:yieldparam)
          h "{|" + object.tags(:yieldparam).map {|t| t.name }.join(", ") + "| ... }"
        else
          ""
        end
      end
      
      def format_meth_name(object)
        (object.scope == :instance ? '#' : '') + h(object.name.to_s)
      end
    end
  end
end