module YARD
  module Generators
    class ConstructorGenerator < Base
      before_generate :has_constructor?
       
      def sections_for(object) 
        [:header, [MethodGenerator]] 
      end
      
      protected
      
      def has_constructor?
        constructor_method ? true : false 
      end
      
      def constructor_method
        current_object.meths.find {|o| o.name == :initialize && o.scope == :instance }
      end
      
      def constructor_method_inherited?
        constructor_method.namespace != current_object
      end
    end
  end
end