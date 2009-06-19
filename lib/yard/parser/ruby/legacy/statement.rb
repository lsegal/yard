module YARD
  module Parser::Ruby::Legacy
    class Statement 
      attr_reader :tokens, :comments, :block
      attr_accessor :comments_range

      def initialize(tokens, block = nil, comments = nil)
        @tokens = tokens
        @block  = block
        @comments = comments
      end
      
      def first_line
        to_s(false)
      end
      
      def to_s(include_block = true)
        tokens.map do |token|
          RubyToken::TkBlockContents === token ? block.to_s : token.text
        end.join
      end
      alias source to_s
      
      def inspect
        l = line - 1
        to_s.split(/\n/).map do |text|
          "\t#{l += 1}:  #{text}"
        end.join("\n")
      end
      alias show inspect
      
      def line
        tokens.first.line_no
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