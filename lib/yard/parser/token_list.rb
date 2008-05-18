module YARD
  module Parser
    class TokenList < Array
      def to_s
        collect {|t| t.text }.join
      end
      
      def squeeze(type = RubyToken::TkSPACE)
        last = nil
        TokenList.new(map {|t| x = t.is_a?(type) && last.is_a?(type) ? nil : t; last = t; x })
      end
    end
  end
end