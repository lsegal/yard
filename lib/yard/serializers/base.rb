module YARD
  module Serializers
    class Base
      def before_serialize; end
      def serialize(object); end
      def after_serialize; end
    end
  end
end