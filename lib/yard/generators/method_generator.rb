module YARD
  module Generators
    class MethodGenerator < Base
      include Helpers::MethodHelper

      before_generate :is_method?
      before_section :aliases, :has_aliases?
      
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
            G(SourceGenerator)
          ]
        ]
      end
      
      protected
      
      def has_aliases?(object)
        !object.aliases.empty?
      end
    end
  end
end