module YARD
  module Generators
    class ModuleGenerator < Base
      before_generate :is_module?
      
      def sections_for(object) 
        [
          :header,
          [
            G(MixinsGenerator), 
            G(DocstringGenerator), 
            G(AttributesGenerator), 
            G(ConstantsGenerator),
            G(MethodSummaryGenerator, :scope => :instance, :visibility => :public),
            G(MethodDetailsGenerator, :scope => :instance, :visibility => :public)
          ]
        ]
      end
    end
  end
end