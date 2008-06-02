module YARD
  module Generators::Helpers
    module UMLHelper
      def uml_visibility(object)
        case object.visibility
        when :public
          '+'
        when :protected
          '#'
        when :private
          '-'
        end
      end
    end
  end
end