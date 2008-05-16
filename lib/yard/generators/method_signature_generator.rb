module YARD
  module Generators
    class MethodSignatureGenerator < Base
      def sections_for(object) 
        [:main] if object.signature
      end
      
      protected
      
      def format_signature(object)
        sig = object.signature.gsub(/^def\s*/, '')
        "#{object.visibility} #{sig}"
      end
    end
  end
end