require 'stringio'
require File.dirname(__FILE__) + '/ruby_lex' 
require File.dirname(__FILE__) + '/namespace'
require File.dirname(__FILE__) + '/code_object'
require File.dirname(__FILE__) + '/handlers/all_handlers'

module YARD
  ##
  # Responsible for parsing a source file into the namespace
  class SourceParser 
    attr_reader :file
    
    def self.parse(content)
      new.parse(content)
    end
    
    def self.parse_string(content)
      new.parse(StringIO.new(content))
    end
    
    attr_accessor :current_namespace
    
    def initialize
      @current_namespace = NameStruct.new(Namespace.root)
    end
    
    ##
    # Creates a new SourceParser that parses a file and returns
    # analysis information about it.
    #
    # @param [String, TokenList, StatementList] content the source file to parse
    def parse(content = __FILE__)
      case content
      when String
        @file = content
        statements = StatementList.new(IO.read(content))
      when TokenList
        statements = StatementList.new(content)
      when StatementList
        statements = content
      else
        if content.respond_to? :read
          statements = StatementList.new(content.read)
        else
          raise ArgumentError, "Invalid argument for SourceParser::parse: #{content.inspect}:#{content.class}"
        end
      end
      
      top_level_parse(statements)
    end
    
    private
      def top_level_parse(statements)
        statements.each do |stmt|
          find_handlers(stmt).each do |handler| 
            handler.new(self, stmt).process
          end
        end
      end
    
      def find_handlers(stmt)
        CodeObjectHandler.subclasses.find_all {|sub| sub.handles? stmt.tokens }
      end
  end
  
  class StatementList < Array
    include RubyToken

    # The following list of tokens will require a block to be opened 
    # if used at the beginning of a statement.
    @@open_block_tokens = [TkCLASS, TkDEF, TkMODULE, TkUNTIL,
                           TkIF, TkUNLESS, TkWHILE, TkFOR, TkCASE]

    ##
    # Creates a new statement list
    #
    # @param [TokenList, String] content the tokens to create the list from
    def initialize(content)
      if content.is_a? TokenList
        @tokens = content
      elsif content.is_a? String
        parse_tokens(content)
      else 
        raise ArgumentError, "Invalid content for StatementList: #{content.inspect}:#{content.class}"
      end

      parse_statements
    end

    private
      def parse_tokens(content)
        @tokens = TokenList.new
        lex = RubyLex.new(content)
        while tk = lex.token do @tokens << tk end
      end

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
        last_tk, before_last_tk = nil, nil
        open_parens = 0

        while tk = @tokens.shift
          #p tk.class
          open_parens += 1 if [TkLPAREN, TkLBRACK].include? tk.class
          open_parens -= 1 if [TkRPAREN, TkRBRACK].include?(tk.class) if open_parens > 0
          
#          raise block.to_s + " TOKEN #{tk.inspect}" if open_parens < 0

          # Get the initial comments
          if statement.empty?
            # Two new-lines in a row will destroy any comment blocks
            if tk.class == TkCOMMENT && last_tk.class == TkNL && 
              (before_last_tk && (before_last_tk.class == TkNL || before_last_tk.class == TkSPACE))
              comments = nil
            elsif tk.class == TkCOMMENT
              # Remove the "#" and up to 1 space before the text
              # Since, of course, the convention is to have "# text"
              # and not "#text", which I deem ugly (you heard it here first)
              comments ||= []
              comments << (tk.text[/^#+\s{0,1}(\s*[^\s#].+)/, 1] || "") 
              comments.pop if comments.size == 1 && comments.first =~ /^\s*$/
            end
          end
                    
          # Ignore any initial comments or whitespace
          unless statement.empty? && [TkSPACE, TkNL, TkCOMMENT].include?(tk.class)
            # Decrease if end or '}' is seen
            level -= 1 if [TkEND, TkRBRACE].include?(tk.class)

            # If the level is greater than 0, add the code to the block text
            # otherwise it's part of the statement text
            if stmt_number > 0
              block ||= TokenList.new
              block << tk
            elsif stmt_number == 0 && tk.class != TkNL && tk.class != TkCOMMENT
              statement << tk 
            end

#            puts "#{tk.line_no} #{level} #{tk} \t#{tk.text} #{tk.lex_state}" 

            # Increase level if we have a 'do' or block opening
            if tk.class == TkLBRACE
              level += 1    
            elsif [TkDO, TkfLBRACE, TkBEGIN].include?(tk.class)
              #p "#{tk.line_no} #{level} #{tk} \t#{tk.text} #{tk.lex_state}" 
              level += 1    
              open_block = false  # Cancel our wish to open a block for the if, we're doing it now
            end

            # Vouch to open a block when this statement would otherwise end
            open_block = true if (new_statement || (last_tk && last_tk.lex_state == EXPR_BEG)) && @@open_block_tokens.include?(tk.class)

            # Check if this token creates a new statement or not
            #puts "#{open_parens} open brackets for: #{statement.to_s}"
            if open_parens == 0 && ([TkSEMICOLON, TkNL, TkEND_OF_SCRIPT].include?(tk.class) ||
              (statement.first.class == TkDEF && tk.class == TkRPAREN))
              # Make sure we don't have any running expressions
              # This includes things like
              #
              # class <
              #   Foo
              # 
              # if a ||
              #    b
              if [EXPR_END, EXPR_ARG].include? last_tk.lex_state
                stmt_number += 1
                new_statement = true
                #p "NEW STATEMENT #{statement.to_s}"

                # The statement started with a if/while/begin, so we must go to the next level now
                if open_block
                  open_block = false
                  level += 1
                end
              end
            elsif tk.class != TkSPACE
              new_statement = false 
            end

            # Else keyword is kind of weird
            if tk.is_a? RubyToken::TkELSE
              new_statement = true
              stmt_number += 1
              open_block = false
            end

            # We're done if we've ended a statement and we're at level 0
            break if new_statement && level == 0
          end

          before_last_tk = last_tk
          last_tk = tk # Save last token
        end

        # Return the code block with starting token and initial comments
        # If there is no code in the block, return nil
        comments = comments.compact if comments
        statement.empty? ? nil : Statement.new(statement, block, comments)
      end
  end

  class TokenList < Array
    def to_s
      collect {|t| t.text }.join
    end
  end

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
  
  class NameStruct
    attr_accessor :object, :attributes
    def initialize(object)
      @object, @attributes = object, { :visibility => :public, :scope => :instance }
    end
  end
end