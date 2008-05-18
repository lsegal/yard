module YARD
  module Serializers
    class Base
      attr_reader :options
      
      def initialize(opts = {})
        @options = SymbolHash[opts]
      end
      
      def before_serialize; end
      def serialize(object, data) end
      def after_serialize; end
    end
  end
end