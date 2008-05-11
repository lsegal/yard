module YARD
  module Parser
    class TokenList < Array
      def to_s
        collect {|t| t.text }.join
      end
    end
  end
end