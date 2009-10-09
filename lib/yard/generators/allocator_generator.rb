module YARD
  module Generators
    class AllocatorGenerator < Base
      before_generate :has_allocator?
       
      def sections_for(object) 
        [:header, [G(MethodGenerator)]] 
      end
      
      protected
      
      def has_allocator?
        allocator_method ? true : false 
      end
      
      def allocator_method
        current_object.meths.find {|o| o.name == :new && o.scope == :class }
      end
      
      def allocator_method_inherited?
        allocator_method.namespace != current_object
      end
    end
  end
end
