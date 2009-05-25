require 'ripper'

module YARD
  module Parser
    module Ruby
      class ParserSyntaxError < UndocumentableError; end
      
      class RubyParser < Ripper
        attr_reader :ast, :charno, :comments, :file, :tokens
        alias root ast

        def initialize(source, filename, *args)
          super
          @file = filename
          @source = source
          @tokens = []
          @comments = {}
          @charno = 0
        end

        def parse
          @ast = super
          @ast.full_source = @source
          @ast.file = @file
          freeze_tree
          insert_comments
          self
        end
        
        def enumerator
          ast.children
        end
        
        private

        PARSER_EVENT_TABLE.each do |event, arity|
          node_class = case event
          when /_ref\Z/
            :ReferenceNode
          when :params
            :ParameterNode
          when :call, :fcall, :command, :command_call
            :MethodCallNode
          when :if, :elsif, :if_mod, :unless, :unless_mod
            :ConditionalNode
          else
            :AstNode
          end
                    
          if /_new\z/ =~ event and arity == 0
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}
                #{node_class}.new(:list, [], line: lineno, char: charno)
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
                #{node_class}.new(:#{event}, args, line: lineno, char: charno)
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
          ParameterNode.new(:params, args, line: lineno, char: charno)
        end

        def on_comment(comment)
          visit_token(:comment, comment)
          
          comment = comment.gsub(/^\#{1,2}\s{0,1}/, '').chomp
          append_comment = @comments[lineno - 1]
          
          if append_comment
            @comments.delete(lineno - 1)
            comment = append_comment + "\n" + comment
          end
          
          @comments[lineno] = comment
        end
        
        def on_parse_error(msg)
          raise ParserSyntaxError, "syntax error in `#{file}`:(#{lineno},#{column}): #{msg}"
        end
        
        def insert_comments
          root.traverse do |node|
            next if node.type == :list
            if node.line
              node.line.downto(node.line - 2) do |line|
                comment = @comments[line]
                if comment && !comment.empty?
                  node.docstring = comment
                  comments.delete(line)
                  break
                end
              end
            end
          end
        end
        
        def freeze_tree(node = nil)
          node ||= root
          node.children.each do |child|
            child.parent = node
            freeze_tree(child)
          end
          node.reset_line_info
        end
      end
    end
  end
end