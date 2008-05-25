module YARD
  module Generators
    class MixinsGenerator < Base
      before_generate :has_mixins?
      
      def sections_for(object) [:header] end
        
      protected
      
      def has_mixins?(object)
        !object.mixins.empty?
      end
    end
  end
end