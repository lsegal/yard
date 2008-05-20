module YARD
  module Generators
    class TagsGenerator < Base
      def sections_for(object)
        if format == :html
          [:header, :tags, :footer]
        else
          [:header, :params, :returns] #[:raises, :yields, :yieldparams]
        end
      end
      
      protected
      
      def format_tag_types(typelist)
        return "" if typelist.nil?
        typelist = typelist.map {|t| t[0, 1] == '#' ? t : linkify(t) }
        typelist.empty? ? "" : "[" + typelist.join(", ") + "]"
      end
    end
  end
end