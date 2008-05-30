module YARD
  module Serializers
    class ProcessSerializer < Base
      def initialize(cmd)
        @cmd = cmd
      end
      
      def serialize(object, data)
        IO.popen(@cmd, 'w') {|io| io.write(data) }
      end
    end
  end
end

