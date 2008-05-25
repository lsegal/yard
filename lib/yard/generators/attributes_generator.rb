module YARD
  module Generators
    class AttributesGenerator < Base
      def before_section(object)
        size = object.class_attributes.size + object.instance_attributes.size
        size > 0 ? super : false
      end
      
      def sections_for(object) [:header] end
    end
  end
end