module YARD
  module Generators
    class ConstructorGenerator < Base
      def sections_for(object) 
        [:header, [MethodGenerator]] 
      end
      
      protected
      
      def constructor_method
        current_object.meths.find {|o| o.name == :initialize && o.scope == :instance }
      end
      
      def constructor_method_inherited?
        constructor_method.namespace != current_object
      end
    end
  end
end