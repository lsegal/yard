module YARD
  module Generators
    class MethodGenerator < Base
      include Helpers::MethodHelper

      before_generate :is_method?
      before_section :aliases, :has_aliases?
      before_section :source, :isnt_overload?
      
      def sections_for(object) 
        [
          :header,
          [
            :title,
            [
              G(MethodSignatureGenerator), 
              :aliases
            ], 
            G(DeprecatedGenerator), 
            G(DocstringGenerator), 
            G(TagsGenerator), 
            G(OverloadsGenerator),
            :source
          ]
        ]
      end
      
      protected

      def source(object)
        render_section(G(SourceGenerator), object)
      end

      def has_aliases?(object)
        !object.aliases.empty?
      end

      def isnt_overload?(object)
        !object.is_a?(Tags::OverloadTag)
      end
    end
  end
end
