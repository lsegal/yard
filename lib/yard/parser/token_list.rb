module YARD
  module Parser
    class TokenList < Array
      include RubyToken
      
      def initialize(content = nil)
        self << content if content
      end
      
      def to_s
        collect {|t| t.text }.join
      end
      
      # @param [TokenList, Token, String] tokens
      #   A list of tokens. If the token is a string, it
      #   is parsed with {RubyLex}.
      def push(*tokens)
        tokens.each do |tok|
          if tok.is_a?(TokenList) || tok.is_a?(Array)
            concat tok
          elsif tok.is_a?(Token)
            super tok
          elsif tok.is_a?(String)
            parse_content(tok)
          else
            raise ArgumentError, "Expecting token, list of tokens or string of code to be tokenized. Got #{tok.class}"
          end
        end
      end
      alias_method :<<, :push
      
      def squeeze(type = TkSPACE)
        last = nil
        TokenList.new(map {|t| x = t.is_a?(type) && last.is_a?(type) ? nil : t; last = t; x })
      end
      
      private
      
      def parse_content(content)
        lex = RubyLex.new(content)
        while tk = lex.token do self << tk end
      end
    end
  end
end