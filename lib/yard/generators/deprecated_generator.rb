module YARD
  module Generators
    class DeprecatedGenerator < Base
      before_generate :is_deprecated?
      
      def sections_for(object) [:main] end
        
      protected
      
      def is_deprecated?(object)
        object.tag(:deprecated) ? true : false
      end
    end
  end
end