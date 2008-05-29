module YARD
  module Generators
    class ClassGenerator < Base
      before_generate :is_class?
      
      def sections_for(object) 
        [
          :header,
          [
            G(InheritanceGenerator), 
            G(MixinsGenerator), 
            G(DocstringGenerator), 
            G(AttributesGenerator), 
            G(ConstantsGenerator),
            G(ConstructorGenerator),
            G(VisibilityGroupGenerator, :visibility => :public),
            G(VisibilityGroupGenerator, :visibility => :protected),
            G(VisibilityGroupGenerator, :visibility => :private)
          ]
        ]
      end
    end
  end
end