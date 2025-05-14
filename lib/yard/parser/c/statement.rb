# frozen_string_literal: true
module YARD
  module Parser
    module C
      class Statement
        attr_accessor :source, :line, :file, :comments_hash_flag

        # @deprecated Groups are now defined by directives
        # @see Tags::GroupDirective
        attr_accessor :group

        def initialize(source, file = nil, line = nil)
          @source = source
          @file = file
          @line = line
        end

        def line_range
          line...(line + source.count("\n"))
        end

        def comments_range
          comments.line_range
        end

        def first_line
          source.split("\n").first
        end

        alias signature first_line

        def show
          "\t#{line}: #{first_line}"
        end
      end

      class BodyStatement < Statement
        attr_accessor :comments
      end

      class ToplevelStatement < Statement
        attr_accessor :block, :declaration, :comments
      end

      class Comment < Statement
        include CommentParser

        attr_accessor :type, :overrides, :statement

        def initialize(source, file = nil, line = nil)
          super(parse_comments(source), file, line)
        end

        def comments; self end
      end
    end
  end
end
