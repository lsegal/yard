module YARD
  module Serializers
    class StdoutSerializer < Base
      def initialize(wrap = nil)
        @wrap = wrap
      end
      
      def serialize(object, data)
        print(@wrap ? word_wrap(data, @wrap) : data)
      end
      
      private
      
      def word_wrap(text, length = 80)
        # See ruby-talk/10655 / Ernest Ellingson
        text.gsub(/\t/,"     ").gsub(/.{1,50}(?:\s|\Z)/){($& + 
          5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
      end
    end
  end
end