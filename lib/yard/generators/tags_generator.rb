module YARD
  module Generators
    class TagsGenerator < Base
      def sections_for(object)
        [:header, :params, :raises, :returns, :yields, :yieldparams]
      end
      
      def format_tag_types(typelist)
        typelist.empty? ? "" : "[" + typelist.join(", ") + "]"
      end
    end
  end
end