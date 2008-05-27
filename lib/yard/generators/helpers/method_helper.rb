module YARD
  module Generators::Helpers
    module MethodHelper
      protected
      
      def format_def(object)
        h(object.signature.gsub(/^def\s*(?:.+?(?:\.|::)\s*)?/, ''))
      end
      
      def format_return_types(object)
        typenames = "Object"
        if object.has_tag?(:return)
          types = object.tags(:return).map do |t| 
            t.types.map do |type| 
              type.gsub(/(^|[<>])\s*([^<>#]+)\s*(?=[<>]|$)/) {|m| $1 + linkify($2) }
            end
          end.flatten
          typenames = types.size == 1 ? types.first : h("[#{types.join(", ")}]")
        end
        typenames
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