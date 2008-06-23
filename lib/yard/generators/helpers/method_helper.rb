module YARD
  module Generators::Helpers
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
    end
  end
end