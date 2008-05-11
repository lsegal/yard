module YARD
  module Parser
    class Statement 
      attr_reader :tokens, :comments, :block

      def initialize(tokens, block = nil, comments = nil)
        @tokens = clean_tokens(tokens)
        @block  = block
        @comments = comments
      end

      private
        def clean_tokens(tokens)
          last_tk = nil
          tokens.reject do |tk| 
            tk.is_a?(RubyToken::TkNL) || 
            (last_tk.is_a?(RubyToken::TkSPACE) && 
            last_tk.class == tk.class) && last_tk = tk 
          end
        end
    end
  end
end