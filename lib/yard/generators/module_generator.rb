module YARD
  module Generators
    class ModuleGenerator < Base
      before_generate :is_module?
      
      def sections_for(object) 
        [
          :header,
          [
            G(MixinsGenerator, :scope => :class),
            G(MixinsGenerator, :scope => :instance),
            G(DocstringGenerator), 
            G(AttributesGenerator), 
            G(ConstantsGenerator),
            G(VisibilityGroupGenerator, :visibility => :public),
            G(VisibilityGroupGenerator, :visibility => :protected),
            G(VisibilityGroupGenerator, :visibility => :private)
          ]
        ]
      end
    end
  end
end
