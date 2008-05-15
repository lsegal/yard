module YARD
  module Generators
    class DeprecatedGenerator < Base
      def sections_for(object) [:main] end
    end
  end
end