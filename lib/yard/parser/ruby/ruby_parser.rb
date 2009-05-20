require 'ripper'

module YARD
  module Parser
    module Ruby
      class ParserSyntaxError < SyntaxError; end
      
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

        attr_reader :ast, :charno, :comments, :file, :tokens

        def initialize(source, filename, *args)
          super
          @file = filename
          @source = source
          @tokens = []
          @comments = []
          @charno = 0
        end

        def parse
          @ast = super
          @ast.full_source = @source
          @ast.file = @file
          insert_comments
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
          add_token(token, data)
          AstNode.new(token, [data], line: lineno, char: ch, token: true)
        end
        
        def add_token(token, data)
          if @tokens.last && @tokens.last[0] == :symbeg
            @tokens[-1] = [:symbol, ":" + data]
          else
            @tokens << [token, data]
          end
        end

        def on_program(*args)
          args.first
        end

        def on_body_stmt(*args)
          args.first
        end

        def on_params(*args)
          args.map! do |arg|
            if arg.class == Array
              if arg.first.class == Array
                arg.map! do |sub_arg|
                  if sub_arg.class == Array
                    AstNode.new(:default_arg, sub_arg, line: lineno, char: charno)
                  else
                    sub_arg
                  end
                end
              end
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
            @comments.last.first.push(comment.gsub(/^\#{1,2}\s{0,1}/, '').chomp)
            @comments.last[-1] = lineno
          else
            @comments << [[comment[1..-1]], lineno]
          end
        end
        
        def on_parse_error(msg)
          raise ParserSyntaxError, "in `#{@file}`:(#{lineno},#{column}): #{msg}"
        end
        
        def insert_comments
          comments = @comments.dup
          @ast.traverse do |node|
            comments.each.with_index do |c, i|
              next if c.empty? || node.line.nil?
              if node.line.between?(c.last, c.last + 2)
                comments.delete_at(i)
                node.docstring = c.first.join("\n")
                break
              end
            end
          end
        end
      end
    end
  end
end