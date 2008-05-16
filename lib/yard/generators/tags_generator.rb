module YARD
  module Generators
    class TagsGenerator < Base
      def sections_for(object)
        [:header, :params, :returns] #[:raises, :yields, :yieldparams]
      end
      
      protected
      
      def format_tag_types(typelist)
        typelist.empty? ? "" : "[" + typelist.join(", ") + "]"
      end
    end
  end
end