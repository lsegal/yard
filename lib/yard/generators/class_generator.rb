module YARD
  module Generators
    class ClassGenerator < Base
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
            MethodSummaryGenerator.new(options, :ignore_serializer => true, 
              :scope => :instance, :visibility => :public
            )
          ]
        ]
      end
    end
  end
end