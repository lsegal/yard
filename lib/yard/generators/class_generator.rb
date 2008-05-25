module YARD
  module Generators
    class ClassGenerator < Base
      def sections_for(object) 
        [InheritanceGenerator, MixinsGenerator, DocstringGenerator, ConstructorGenerator]
      end
    end
  end
end