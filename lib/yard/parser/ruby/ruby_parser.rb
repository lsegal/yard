require 'ripper'

module YARD
  module Parser
    module Ruby
      class RubyParser < Ripper
        class << self
          def no_comment(*toks)
            (@no_comments ||= []).push(*toks)
          end

          attr_reader :no_comments
        end

        no_comment  :aref, :aref_field, :arg_paren, :brace_block, :do_block,
                    :dot2, :dot3, :excessed_comma, :params, :paren, :sclass,
                    :args_add_block, :string_literal, :binary, :string_content,
                    :void_stmt, :stmt_body, :var_ref, :args, :self, :string_embexpr,
                    :string_dvar, :xstring_literal, :rest_param, :blockarg

        attr_reader :ast, :charno, :comments, :file

        def initialize(source, filename, *args)
          super
          @file = filename
          @source = source
          @comments = []
          @charno = 0
        end
        
        def tokens
          @source
        end

        def parse
          @ast = super
          @ast.insert_comments(@comments)
          @ast.full_source = @source
          @ast.file = @file
          self
        end
        
        def enumerator
          ast.children
        end
        
        private

        PARSER_EVENT_TABLE.each do |event, arity|
          if /_new\z/ =~ event and arity == 0
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}
                AstNode.new(:list, [], line: lineno, char: charno)
              end
            eof
          elsif /_add(_.+)?\z/ =~ event
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(list, item)
                list.push(item)
                list
              end
            eof
          elsif /_ref\z/ =~ event
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(*args)
                args.first
              end
            eof
          else
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(*args)
                AstNode.new(:#{event}, args, line: lineno, char: charno)
              end
            eof
          end
        end

        SCANNER_EVENTS.each do |event|
          module_eval(<<-eof, __FILE__, __LINE__ + 1)
            def on_#{event}(tok)
              visit_token(:#{event}, tok)
            end
          eof
        end

        def visit_token(token, data)
          ch = charno
          @charno += data.length 
          AstNode.new(token, [data], line: lineno, char: ch, token: true)
        end

        def on_program(*args)
          args.first
        end

        def on_body_stmt(*args)
          args.first
        end

        def on_params(*args)
          args.map! do |arg|
            if Array === arg
              arg = arg.first if Array === arg.first 
              AstNode.new(:list, arg, line: lineno, char: charno)
            else
              arg
            end
          end
          AstNode.new(:params, args, line: lineno, char: charno)
        end

        def on_comment(comment)
          visit_token(:comment, comment)

          append_comment = false
          if @comments.size > 0 && @comments.last.last == lineno - 1
            append_comment = true
          end
  
          if append_comment
            @comments.last.first.push(comment[1..-1])
            @comments.last[-1] = lineno
          else
            @comments << [[comment[1..-1]], lineno]
          end
        end
        
        def on_parse_error(msg)
          raise SyntaxError, "in `#{@file}`:(#{lineno},#{column}): #{msg}"
        end
      end
    end
  end
end