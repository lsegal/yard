module YARD
  module Generators
    class RootGenerator < Base
      before_generate :is_root?
      before_generate :has_data?
      
      def sections_for(object) 
        [
          :header,
          [
            G(MixinsGenerator, :scope => :class),
            G(MixinsGenerator, :scope => :instance),
            G(ConstantsGenerator),
            G(VisibilityGroupGenerator, :visibility => :public),
            G(VisibilityGroupGenerator, :visibility => :protected),
            G(VisibilityGroupGenerator, :visibility => :private)
          ]
        ]
      end
      
      private
      
      def has_data?(object)
        object.meths.size > 0 || object.constants.size > 0
      end
      
      def is_root?(object)
        object == Registry.root
      end
    end
  end
end
