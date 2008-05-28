module YARD
  module Generators
    class MethodSummaryGenerator < MethodListingGenerator
      before_generate :is_namespace?
      before_section  :summary,   :has_methods?
      before_section  :inherited, :has_inherited_methods?
      before_section  :included,  :has_included_methods?
      
      def sections_for(object)
        [
          :header, 
          [
            :summary,
            :inherited,
            :included
          ]
        ]
      end
    end
  end
end