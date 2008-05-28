module YARD
  module Generators
    class VisibilityGroupGenerator < Base
      attr_reader :visibility
      
      def initialize(*args)
        super
        @visibility = options[:visibility]
      end
      
      before_generate :is_namespace?

      def sections_for(object)
        [
          :header,
          [
            G(MethodSummaryGenerator, :visibility => visibility, :scope => :class),
            G(MethodSummaryGenerator, :visibility => visibility, :scope => :instance),
            G(MethodDetailsGenerator, :visibility => visibility, :scope => :class),
            G(MethodDetailsGenerator, :visibility => visibility, :scope => :instance)
          ]
        ]
      end
    end
  end
end