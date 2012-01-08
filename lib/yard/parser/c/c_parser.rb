module YARD
  module Parser
    module C
      class CParser < Base
        def initialize(source, file = '(stdin)')
          @file = file
          @namespaces = {}
          @content = source
          @index = 0
          @line = 1
          @state = nil
          @newline = true
          @statements = []
          @last_comment = nil
          @last_statement = nil
        end

        def parse
          parse_toplevel
          enumerator
        end

        def enumerator
          @statements
        end

        def tokenize
          raise NotImplementedError, "no tokenization support for C/C++ files"
        end

        private

        def parse_toplevel
          advance_loop do
            case char
            when /['"]/; consume_quote(char)
            when '#'; consume_directive
            when '/'; consume_comment
            when /\s/; consume_whitespace
            else consume_toplevel_statement
            end
          end
        end

        def consume_quote(type = '"')
          advance
          advance_loop do
            case char
            when "\n"; advance; nextline
            when '\\'; advance(2)
            when type; advance; return
            else advance
            end
          end
        end

        def consume_directive
          return unless @newline
          @last_comment = nil
          @last_statement = nil
          advance_loop do
            if char == '\\' && nextchar =~ /[\r\n]/
              advance_loop { advance; break(nextline) if char == "\n" }
            elsif char == "\n"
              return
            end
            advance
          end
        end

        def consume_toplevel_statement
          @newline = false
          start = @index
          line = @line
          decl = consume_until(/[{;]/)
          return nil if decl =~ /\A\s*\Z/
          statement = ToplevelStatement.new(nil, @file, line)
          @statements << statement
          attach_comment(statement)
          stmts = nil
          if prevchar == '{'
            stmts = consume_body_statements
            case decl
            when /\A(typedef|class|struct|union)\b/
              consume_until(';')
            else
              consume_until('}')
            end
          end
          statement.source = @content[start..@index]
          statement.block = stmts
          statement.declaration = decl
          #stmts.each {|stmt| stmt.parent = statement } if stmts
        end

        def consume_body_statements
          stmts = []
          brace_level = 1
          while true
            strip_non_statement_data
            start, line = @index, @line
            consume_until(/[{};]/)
            brace_level += 1 if prevchar == '{'
            brace_level -= 1 if prevchar == '}'

            if prevchar.empty? || (brace_level <= 0 && prevchar == '}')
              back
              break
            end
            end_chr = @index
            end_chr -= 1 if prevchar == '}'
            src = @content[start...@index]
            if src && src !~ /\A\s*\Z|\A\}\Z/
              stmt = BodyStatement.new(src, @file, line)
              attach_comment(stmt)
              stmts << stmt
            end
          end
          stmts
        end

        def strip_non_statement_data
          start = @index
          begin
            start = @index
            case char
            when /\s/; consume_whitespace
            when '#';  consume_directive
            when '/';  consume_comment
            end
          end until start == @index
        end

        def consume_whitespace
          advance_loop { break if char !~ /[\t \r\n]/; nextline if char == "\n"; advance }
        end

        def consume_comment
          return(advance) unless nextchar == '*' || nextchar == '/'
          line = @line
          type = nextchar == '*' ? :multi : :line
          advance(2)
          comment = ""
          advance_loop do
            comment << char
            if type == :multi 
              nextline if char == "\n"
              if char(2) == '*/'
                comment << '/'
                stmt = Comment.new(comment, @file, line)
                stmt.type = type
                attach_comment(stmt)
                @statements << stmt
                return advance(2)
              end
            elsif char == "\n"
              stmt = Comment.new(comment[0...-1], @file, line)
              stmt.type = type
              attach_comment(stmt)
              @statements << stmt
              return
            end
            advance
          end
        end

        def consume_until(end_char, bracket_level = 0, brace_level = 0)
          end_char = /#{end_char}/ if end_char.is_a?(String)
          start = @index
          advance_loop do
            chr = char
            @newline = false if chr !~ /\s/
            case chr
            when /\s/; consume_whitespace
            when /['"]/; consume_quote(char)
            when '{'; advance; brace_level += 1
            when '}'; advance; brace_level -= 1
            when '('; advance; bracket_level += 1
            when ')'; advance; bracket_level -= 1
            else advance
            end

            if chr =~ end_char && (chr == '{' || chr == '(')
              break
            elsif chr =~ end_char && bracket_level <= 0 && brace_level <= 0
              break
            end
          end
          return @content[start...@index]
        end
        
        def attach_comment(statement)
          if Comment === statement
            if @last_statement && @last_statement.line == statement.line
              @last_statement.comments = statement
              statement.statement = @last_statement
            end
            @last_comment = statement
            @last_statement = nil
          else
            if @last_comment
              statement.comments = @last_comment
              @last_comment.statement = statement
            end
            @last_statement = statement
            @last_comment = nil
          end
        end

        def advance(num = 1) @index += num end
        def back(num = 1) @index -= num end

        def advance_loop(&block)
          while @index <= @content.size; yield end
        end

        def nextline
          @line += 1
          @newline = true
        end

        def char(num = 1) @content[@index, num] end
        def prevchar(num = 1) @content[@index - 1, num] end
        def nextchar(num = 1) @content[@index + 1, num] end
      end
    end
  end
end
