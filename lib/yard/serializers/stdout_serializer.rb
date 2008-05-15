module YARD
  module Serializers
    class StdoutSerializer < Base
      def serialize(object, data)
        print data
      end
    end
  end
end