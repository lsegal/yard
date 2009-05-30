module YARD
  module Generators
    class SourceGenerator < Base
      include Helpers::MethodHelper
      
      def sections_for(object) 
        [:main] if object.source
      end
    end
  end
end