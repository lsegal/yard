module YARD
  module Serializers
    class Base
      attr_reader :options
      
      def initialize(opts = {})
        @options = SymbolHash.new(false).update(opts)
      end
      
      def before_serialize; end
      def serialize(object, data) end
      def after_serialize(data); end
      def serialized_path(object) end
    end
  end
end