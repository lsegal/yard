module YARD
  module Generators
    class AttributesGenerator < Base
      include Helpers::MethodHelper
      
      before_generate :has_attributes?
      before_list :includes
      
      def sections_for(object) [:header] end
        
      protected
      
      def includes
        extend Helpers::UMLHelper if format == :text
      end
      
      def has_attributes?
        current_object.class_attributes.size + current_object.instance_attributes.size > 0
      end
    end
  end
end