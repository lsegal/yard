module YARD
  module Generators
    class ClassGenerator < Base
      before_generate :is_class?
      
      def sections_for(object) 
        [
          :header,
          [
            InheritanceGenerator, 
            MixinsGenerator, 
            DocstringGenerator, 
            AttributesGenerator, 
            ConstantsGenerator,
            ConstructorGenerator,
            G(MethodSummaryGenerator, :scope => :instance, :visibility => :public),
            G(MethodDetailsGenerator, :scope => :instance, :visibility => :public)
          ]
        ]
      end
    end
  end
end