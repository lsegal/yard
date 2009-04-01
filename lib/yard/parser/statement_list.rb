module YARD
  module Parser
    class StatementList < Array
      include RubyToken

      # The following list of tokens will require a block to be opened 
      # if used at the beginning of a statement.
      OPEN_BLOCK_TOKENS = [TkCLASS, TkDEF, TkMODULE, TkUNTIL,
                           TkIF, TkUNLESS, TkWHILE, TkFOR, TkCASE]
      COLON_TOKENS = [TkUNTIL, TkIF, TkUNLESS, TkWHILE, TkCASE, TkWHEN]

      ##
      # Creates a new statement list
      #
      # @param [TokenList, String] content the tokens to create the list from
      def initialize(content)
        if content.is_a? TokenList
          @tokens = content.dup
        elsif content.is_a? String
          @tokens = TokenList.new(content)
        else 
          raise ArgumentError, "Invalid content for StatementList: #{content.inspect}:#{content.class}"
        end

        parse_statements
      end

      private

      def parse_statements
        while stmt = next_statement do self << stmt end
      end

      # MUST REFACTOR THIS CODE
      # WARNING WARNING WARNING             WARNING
      # MUST REFACTOR THIS CODE                |
      # OR CHILDREN WILL DIE                   V
      # WARNING WARNING WARNING             WARNING
      # THIS IS MEANT TO BE UGLY.
      def next_statement
        @statement, @block, @comments = TokenList.new, nil, nil
        @first_statement, @new_statement, @open_block = true, true, false
        @last_tk, @last_ns_tk, @before_last_tk = nil, nil, nil
        @level, @open_parens = 0, 0

        while tk = @tokens.shift
          break if process_token(tk)

          @before_last_tk = @last_tk
          @last_tk = tk # Save last token
          @last_ns_tk = tk unless [TkSPACE, TkNL, TkEND_OF_SCRIPT].include? tk.class
        end

        # Return the code block with starting token and initial comments
        # If there is no code in the block, return nil
        @comments = @comments.compact if @comments
        if @block || !@statement.empty?
          Statement.new(@statement, @block, @comments)
        else
          nil
        end
      end

      ##
      # Processes a single token, modifying instance variables accordingly
      #
      # @param [RubyToken::Token] tk the token to process
      # @return [Boolean] whether or not the statement has been ended by +tk+
      def process_token(tk)
        # !!!!!!!!!!!!!!!!!!!! REMOVED TkfLPAREN, TkfLBRACK
        @open_parens += 1 if [TkLPAREN, TkLBRACK].include? tk.class
        @open_parens -= 1 if [TkRPAREN, TkRBRACK].include? tk.class

        return if process_initial_comment(tk)

        # Ignore any other initial comments or whitespace
        return if @statement.empty? && @first_statement && [TkSPACE, TkNL, TkCOMMENT].include?(tk.class)

        # Decrease if end or '}' is seen
        @level -= 1 if [TkEND, TkRBRACE].include?(tk.class)

        process_block_opener(tk)
        push_token(tk)
        process_block_statement(tk)
        @new_statement = false unless process_new_statement(tk)
        process_else(tk)

        # We're done if we've ended a statement and we're at level 0
        return true if @new_statement && @level == 0
      end

      ##
      # Processes a comment token that comes before a statement
      #
      # @param [RubyToken::Token] tk the token to process
      # @return [Boolean] whether or not +tk+ was processed as an initial comment
      def process_initial_comment(tk)
        return unless @statement.empty? && tk.class == TkCOMMENT

        # Two new-lines in a row will destroy any comment blocks
        if @last_tk.class == TkNL && @before_last_tk &&
            (@before_last_tk.class == TkNL || @before_last_tk.class == TkSPACE)
          @comments = nil
          return
        end

        # Remove the "#" and up to 1 space before the text
        # Since, of course, the convention is to have "# text"
        # and not "#text", which I deem ugly (you heard it here first)
        @comments ||= []
        @comments << tk.text.gsub(/^#+\s{0,1}/, '')
        @comments.pop if @comments.size == 1 && @comments.first =~ /^\s*$/
        true
      end

      ##
      # Increases nesting level if we have a block-opening keyword
      #
      # @param [RubyToken::Token] tk the token to process
      def process_block_opener(tk)
        return unless [TkLBRACE, TkDO, TkBEGIN].include?(tk.class)

        new_statement!
        @level += 1
      end

      ##
      # Processes an +else+ token
      #
      # @param [RubyToken::Token] tk the token to process
      def process_else(tk)
        return unless tk.class == TkELSE

        new_statement!
        @open_block = false
      end

      ##
      # Processes a newly-opened block statement, such as +if+ or +while+
      #
      # @param [RubyToken::Token] tk the token to process
      def process_block_statement(tk)
        @open_block = [@level, tk.class] if (@new_statement ||
          (@last_tk && @last_tk.lex_state == EXPR_BEG)) &&
          OPEN_BLOCK_TOKENS.include?(tk.class)
      end

      ##
      # Checks if +tk+ opens a new statement
      #
      # @param [RubyToken::Token] tk the token to process
      # @return [Boolean] whether or not a new statement has been opened or remains open
      def process_new_statement(tk)
        return true if tk.class == TkSPACE
        return unless @open_parens == 0 &&
          ((@last_tk && [TkSEMICOLON, TkNL, TkEND_OF_SCRIPT].include?(tk.class)) ||
           (@open_block && @open_block.last == TkDEF && tk.class == TkRPAREN))

        # Make sure we don't have any running expressions
        # This includes things like
        #
        # class <
        #   Foo
        #
        # if a ||
        #    b
        return true unless (@last_tk && [EXPR_END, EXPR_ARG].include?(@last_tk.lex_state)) ||
          (@open_block && [TkNL, TkSEMICOLON].include?(tk.class) && @last_ns_tk.class != @open_block.last)

        new_statement!

        # Unless the statement opened a block, we want to stay on the same level
        return true unless @open_block && @open_block.first == @level

        if tk.class == TkNL && @block.nil?
          @block = TokenList.new
          @block << tk
        end

        @open_block = false
        @level += 1
        true
      end

      ##
      # Adds +tk+ to the current statement, or to the current block
      # if the nesting level is greater than 0
      #
      # @param [RubyToken::Token] tk the token to process
      def push_token(tk)
        if @first_statement
          @statement << tk unless [TkNL, TkSEMICOLON, TkCOMMENT].include?(tk.class)
          return
        end

        @block ||= TokenList.new
        @block << tk
      end

      ##
      # Declares that a new statement is being processed
      def new_statement!
        @new_statement = true
        @first_statement = false
      end
    end
  end
end
