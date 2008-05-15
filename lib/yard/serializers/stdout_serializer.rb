module YARD
  module Serializers
    class StdoutSerializer < Base
      def serialize(object, data)
        puts object.path
        puts data
      end
    end
  end
end