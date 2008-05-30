module YARD
  module Generators
    class MethodMissingGenerator < Base
      before_generate :has_method_missing?
       
      def sections_for(object) 
        [:header, [G(MethodGenerator)]] 
      end
      
      protected
      
      def has_method_missing?
        method_missing_method ? true : false 
      end
      
      def method_missing_method
        current_object.meths.find {|o| o.name == :method_missing && o.scope == :instance }
      end
      
      def method_missing_method_inherited?
        method_missing_method.namespace != current_object
      end
    end
  end
end