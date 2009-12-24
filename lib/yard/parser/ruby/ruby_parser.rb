require 'ripper'

module YARD
  module Parser
    module Ruby
      class RubyParser < Ripper
        attr_reader :ast, :charno, :comments, :file, :tokens
        alias root ast

        def initialize(source, filename, *args)
          super
          @file = filename
          @source = source
          @tokens = []
          @comments = {}
          @map = {}
          @ns_charno = 0
          @list = []
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
        
        MAPPINGS = {
          :BEGIN => "BEGIN",
          :END => "END",
          :alias => "alias",
          :array => :lbracket,
          :arg_paren => :lparen,
          :begin => "begin",
          :blockarg => "&",
          :brace_block => :lbrace,
          :break => "break",
          :case => "case",
          :class => "class",
          :def => "def",
          :defined => "defined?",
          :defs => "def",
          :do_block => "do",
          :else => "else",
          :elsif => "elsif",
          :ensure => "ensure",
          :for => "for",
          :hash => :lbrace,
          :if => "if",
          :lambda => [:tlambda, "lambda"],
          :module => "module",
          :next => "next",
          :paren => :lparen,
          :qwords_literal => :qwords_beg,
          :redo => "redo",
          :regexp_literal => :regexp_beg,
          :rescue => "rescue",
          :rest_param => "*",
          :retry => "retry",
          :return => "return",
          :return0 => "return",
          :sclass => "class",
          :string_embexpr => :embexpr_beg,
          :string_literal => [:tstring_beg, :heredoc_beg],
          :super => "super",
          :symbol => :symbeg,
          :undef => "undef",
          :unless => "unless",
          :until => "until",
          :when => "when",
          :while => "while",
          :xstring_literal => :backtick,
          :yield => "yield",
          :yield0 => "yield",
          :zsuper => "super"
        }
        REV_MAPPINGS = {}
        
        AST_TOKENS = [:CHAR, :backref, :const, :cvar, :gvar, :heredoc_end, :ident,
          :int, :float, :ivar, :label, :period, :regexp_end, :tstring_content, :backtick]

        MAPPINGS.each do |k, v|
          if Array === v
            v.each {|_v| (REV_MAPPINGS[_v] ||= []) << k }
          else
            (REV_MAPPINGS[v] ||= []) << k
          end
        end

        PARSER_EVENT_TABLE.each do |event, arity|
          node_class = AstNode.node_class_for(event)
          
          if /_new\z/ =~ event and arity == 0
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(*args)
                #{node_class}.new(:list, args, listchar: charno...charno, listline: lineno..lineno)
              end
            eof
          elsif /_add(_.+)?\z/ =~ event
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(list, item)
                list.push(item)
                list
              end
            eof
          elsif MAPPINGS.has_key?(event)
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(*args)
                visit_event #{node_class}.new(:#{event}, args)
              end
            eof
          else
            module_eval(<<-eof, __FILE__, __LINE__ + 1)
              def on_#{event}(*args)
                #{node_class}.new(:#{event}, args, listline: lineno..lineno, listchar: charno...charno)
              end
            eof
          end
        end

        SCANNER_EVENTS.each do |event|
          ast_token = AST_TOKENS.include?(event)
          module_eval(<<-eof, __FILE__, __LINE__ + 1)
            def on_#{event}(tok)
              visit_ns_token(:#{event}, tok, #{ast_token.inspect})
            end
          eof
        end
        
        REV_MAPPINGS.select {|k| k.is_a?(Symbol) }.each do |event, value|
          ast_token = AST_TOKENS.include?(event)
          module_eval(<<-eof, __FILE__, __LINE__ + 1)
            def on_#{event}(tok)
              (@map[:#{event}] ||= []) << [lineno, charno]
              visit_ns_token(:#{event}, tok, #{ast_token.inspect})
            end
          eof
        end
        
        [:kw, :op].each do |event|
          module_eval(<<-eof, __FILE__, __LINE__ + 1)
            def on_#{event}(tok)
              unless @last_ns_token == [:kw, "def"] ||
                  (@tokens.last && @tokens.last[0] == :symbeg)
                (@map[tok] ||= []) << [lineno, charno]
              end
              visit_ns_token(:#{event}, tok, true)
            end
          eof
        end

        [:sp, :nl, :ignored_nl].each do |event|
          module_eval(<<-eof, __FILE__, __LINE__ + 1)
            def on_#{event}(tok)
              add_token(:#{event}, tok)
              @charno += tok.length
            end
          eof
        end
        
        def visit_event(node)
          lstart, sstart = *@map[MAPPINGS[node.type]].pop
          node.source_range = Range.new(sstart, @ns_charno - 1)
          node.line_range = Range.new(lstart, lineno)
          node
        end
        
        def visit_event_arr(node)
          mapping = MAPPINGS[node.type].find {|k| @map[k] && !@map[k].empty? }
          lstart, sstart = *@map[mapping].pop
          node.source_range = Range.new(sstart, @ns_charno - 1)
          node.line_range = Range.new(lstart, lineno)
          node
        end

        def visit_ns_token(token, data, ast_token = false)
          add_token(token, data)
          ch = charno
          @last_ns_token = [token, data]
          @charno += data.length
          @ns_charno = charno
          if ast_token
            AstNode.new(token, [data], line: lineno..lineno, char: ch..charno-1, token: true)
          end
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
          args.compact.size == 1 ? args.first : AstNode.new(:list, args)
        end
        alias on_bodystmt on_body_stmt
        
        def on_assoc_new(*args)
          AstNode.new(:assoc, args)
        end

        def on_hash(*args)
          visit_event AstNode.new(:hash, args.first || [])
        end
        
        def on_bare_assoc_hash(*args)
          AstNode.new(:list, args.first)
        end
        
        def on_assoclist_from_args(*args)
          args.first
        end
        
        def on_aref(*args)
          ll, lc = *@map[:aref].pop
          sr = args.first.source_range.first..lc
          lr = args.first.line_range.first..ll
          AstNode.new(:aref, args, char: sr, line: lr)
        end
        
        def on_rbracket(tok)
          (@map[:aref] ||= []) << [lineno, charno]
          visit_ns_token(:rbracket, tok, false)
        end
        
        [:if_mod, :unless_mod, :while_mod].each do |kw|
          node_class = AstNode.node_class_for(kw)
          module_eval(<<-eof, __FILE__, __LINE__ + 1)
            def on_#{kw}(*args)
              sr = args.last.source_range.first..args.first.source_range.last
              lr = args.last.line_range.first..args.first.line_range.last
              #{node_class}.new(:#{kw}, args, line: lr, char: sr)
            end
          eof
        end
        
        def on_qwords_new
          visit_event AstNode.new(:qwords_literal, [])
        end
        
        def on_string_literal(*args)
          visit_event_arr AstNode.new(:string_literal, args)
        end
        
        def on_lambda(*args)
          visit_event_arr AstNode.new(:lambda, args)
        end
        
        def on_string_content(*args)
          AstNode.new(:string_content, args, listline: lineno..lineno, listchar: charno..charno)
        end
        
        def on_rescue(exc, *args)
          exc = AstNode.new(:list, exc) if exc
          visit_event AstNode.new(:rescue, [exc, *args])
        end

        def on_void_stmt
          AstNode.new(:void_stmt, [], line: lineno..lineno, char: charno...charno)
        end

        def on_params(*args)
          args.map! do |arg|
            if arg.class == Array
              if arg.first.class == Array
                arg.map! do |sub_arg|
                  if sub_arg.class == Array
                    AstNode.new(:default_arg, sub_arg, listline: lineno..lineno, listchar: charno..charno)
                  else
                    sub_arg
                  end
                end
              end
              AstNode.new(:list, arg, listline: lineno..lineno, listchar: charno..charno)
            else
              arg
            end
          end
          ParameterNode.new(:params, args, listline: lineno..lineno, listchar: charno..charno)
        end
        
        def on_label(data)
          add_token(:label, data)
          ch = charno
          @charno += data.length
          @ns_charno = charno
          AstNode.new(:label, [data[0...-1]], line: lineno..lineno, char: ch..charno-1, token: true)
        end

        def on_comment(comment)
          visit_ns_token(:comment, comment)
          
          comment = comment.gsub(/^\#{1,2}\s{0,1}/, '').chomp
          append_comment = @comments[lineno - 1]
          
          if append_comment && @comments_last_column == column
            @comments.delete(lineno - 1)
            comment = append_comment + "\n" + comment
          end
          
          @comments[lineno] = comment
          @comments_last_column = column
        end
        
        def on_parse_error(msg)
          raise ParserSyntaxError, "syntax error in `#{file}`:(#{lineno},#{column}): #{msg}"
        end
        
        def insert_comments
          root.traverse do |node|
            next if node.type == :list || node.parent.type != :list
            node.line.downto(node.line - 2) do |line|
              comment = @comments[line]
              if comment && !comment.empty?
                node.docstring = comment
                node.docstring_range = ((line - comment.count("\n"))..line)
                comments.delete(line)
                break
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
        end
      end
    end
  end
end