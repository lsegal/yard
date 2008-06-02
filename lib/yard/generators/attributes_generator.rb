module YARD
  module Generators
    class AttributesGenerator < Base
      include Helpers::MethodHelper
      
      before_generate :has_attributes?
      
      def sections_for(object) [:header] end
        
      protected
      
      def has_attributes?
        current_object.class_attributes.size + current_object.instance_attributes.size > 0
      end
    end
  end
end