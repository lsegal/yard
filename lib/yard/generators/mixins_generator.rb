module YARD
  module Generators
    class MixinsGenerator < Base
      attr_reader :scope
      before_generate :has_mixins?

      def initialize(*args)
        super
        @scope = options[:scope]
      end
      
      def sections_for(object) [:header] end
        
      protected
      
      def has_mixins?(object)
        !object.mixins(@scope).empty?
      end
    end
  end
end
