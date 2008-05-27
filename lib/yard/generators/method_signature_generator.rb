module YARD
  module Generators
    class MethodSignatureGenerator < Base
      include Helpers::MethodHelper

      before_generate :has_signature?
      
      def sections_for(object) 
        [:main] 
      end
      
      protected
      
      def has_signature?(object)
        object.signature ? true : false
      end
    end
  end
end