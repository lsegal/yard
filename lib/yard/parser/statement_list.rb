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
        statement, block, comments = TokenList.new, nil, nil
        stmt_number, level = 0, 0
        new_statement, open_block = true, false
        last_tk, last_ns_tk, before_last_tk = nil, nil, nil
        open_parens = 0

        while tk = @tokens.shift
          #p tk.class
          # !!!!!!!!!!!!!!!!!!!! REMOVED TkfLPAREN, TkfLBRACK
          open_parens += 1 if [TkLPAREN, TkLBRACK].include? tk.class
          open_parens -= 1 if [TkRPAREN, TkRBRACK].include?(tk.class) 
      
          #if open_parens < 0 || level < 0
          #  STDERR.puts block.to_s + " TOKEN #{tk.inspect}"
          #  exit
          #end

          # Get the initial comments
          if statement.empty?
            # Two new-lines in a row will destroy any comment blocks
            if [TkCOMMENT, TkRD_COMMENT].include?(tk.class)  && last_tk.class == TkNL && 
              (before_last_tk && (before_last_tk.class == TkNL || before_last_tk.class == TkSPACE))
              comments = nil
            elsif tk.class == TkCOMMENT || tk.class == TkRD_COMMENT
              # Remove the "#" and up to 1 space before the text
              # Since, of course, the convention is to have "# text"
              # and not "#text", which I deem ugly (you heard it here first)
              comments ||= []
              comments << tk.text.gsub(/^#+\s{0,1}/, '')
              comments.pop if comments.size == 1 && comments.first =~ /^\s*$/
            end
          end
                
          # Ignore any initial comments or whitespace
          unless statement.empty? && [TkSPACE, TkNL, TkRD_COMMENT, TkCOMMENT].include?(tk.class)
            # Decrease if end or '}' is seen
            level -= 1 if [TkEND, TkRBRACE].include?(tk.class)
        
            # If the level is greater than 0, add the code to the block text
            # otherwise it's part of the statement text
            if stmt_number > 0
              #puts "Block of #{statement}"
              #puts "#{stmt_number} #{tk.line_no} #{level} #{open_parens} #{tk.class.class_name} \t#{tk.text.inspect} #{tk.lex_state} #{open_block.inspect}" 
              block ||= TokenList.new
              block << tk
            elsif stmt_number == 0 && tk.class != TkNL && tk.class != TkSEMICOLON && tk.class != TkCOMMENT
              statement << tk 
            end

            #puts "#{tk.line_no} #{level} #{open_parens} #{tk.class.class_name} \t#{tk.text.inspect} #{tk.lex_state} #{open_block.inspect}" 

            # Increase level if we have a 'do' or block opening
            if tk.class == TkLBRACE #|| tk.class == TkfLBRACE
              level += 1    
            elsif [TkDO, TkBEGIN].include?(tk.class) 
              #p "#{tk.line_no} #{level} #{tk} \t#{tk.text} #{tk.lex_state}" 
              level += 1    
              open_block = false  # Cancel our wish to open a block for the if, we're doing it now
            end

            # Vouch to open a block when this statement would otherwise end
            open_block = [level, tk.class] if (new_statement || 
                                (last_tk && last_tk.lex_state == EXPR_BEG)) && 
                                 OPEN_BLOCK_TOKENS.include?(tk.class)

            # Check if this token creates a new statement or not
            #puts "#{open_parens} open brackets for: #{statement.to_s}"
            if open_parens == 0 && ((last_tk && [TkSEMICOLON, TkNL, TkEND_OF_SCRIPT].include?(tk.class)) ||
              (open_block && open_block.last == TkDEF && tk.class == TkRPAREN))
              
              # Make sure we don't have any running expressions
              # This includes things like
              #
              # class <
              #   Foo
              # 
              # if a ||
              #    b
              if (last_tk && [EXPR_END, EXPR_ARG].include?(last_tk.lex_state)) || 
                  (open_block && [TkNL, TkSEMICOLON].include?(tk.class) && last_ns_tk.class != open_block.last)
                stmt_number += 1
                new_statement = true
                #p "NEW STATEMENT #{block.to_s}"

                # The statement started with a if/while/begin, so we must go to the next level now
                if open_block && open_block.first == level
                  if tk.class == TkNL && block.nil?
                    block = TokenList.new
                    block << tk
                  end

                  open_block = false
                  level += 1
                end
              end
            elsif tk.class != TkSPACE
              new_statement = false 
            end

            # Else keyword is kind of weird
            if tk.is_a? TkELSE
              new_statement = true
              stmt_number += 1
              open_block = false
            end

            # We're done if we've ended a statement and we're at level 0
            break if new_statement && level == 0
        
            #raise "Unexpected end" if level < 0
          end
      
          #break if new_statement && level == 0

          before_last_tk = last_tk
          last_tk = tk # Save last token
          last_ns_tk = tk unless [TkSPACE, TkNL, TkEND_OF_SCRIPT].include? tk.class
        end

        # Return the code block with starting token and initial comments
        # If there is no code in the block, return nil
        comments = comments.compact if comments
        statement.empty? ? nil : Statement.new(statement, block, comments)
      end
    end
  end
end