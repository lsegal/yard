# frozen_string_literal: true
module YARD
  module Parser
    module RBS
      # Parses RBS (Ruby type signature) files and produces a list of
      # {Statement} objects for post-processing by handlers.
      #
      # RBS is Ruby's official type signature format (introduced in Ruby 3.0).
      # This parser handles: class/module/interface declarations, method
      # signatures, attribute accessors, mixins, and constants.
      #
      # No external gem dependencies are used; the parser is hand-written.
      class RbsParser < YARD::Parser::Base
        # @param source [String] source code to parse
        # @param filename [String] path to the source file
        def initialize(source, filename)
          @source   = source
          @filename = filename
          @statements = nil
        end

        # Parses the source and returns self.
        # @return [RbsParser] self
        def parse
          lines = @source.lines.map { |l| l.chomp }
          @statements, = parse_body(lines, 0, false)
          self
        end

        # Tokenization is not implemented for RBS.
        def tokenize
          raise NotImplementedError, "RBS parser does not support tokenization"
        end

        # @return [Array<Statement>] top-level statements for the post-processor
        def enumerator
          @statements
        end

        private

        # Parse a sequence of lines, returning statements and the index after the last consumed line.
        #
        # @param lines [Array<String>] source lines
        # @param start [Integer] index to start from (0-based)
        # @param stop_at_end [Boolean] when true, stop parsing when we see a bare `end`
        # @return [Array(Array<Statement>, Integer)] [statements, new_index]
        def parse_body(lines, start, stop_at_end)
          statements        = []
          i                 = start
          pending_comments  = []
          pending_start_1   = nil  # 1-indexed line number of first pending comment

          while i < lines.length
            raw      = lines[i]
            stripped = raw.strip

            if stripped =~ /\A#(.*)/
              # Comment line – accumulate into pending docstring.
              # Strip at most one leading space (conventional RBS doc style).
              pending_comments << $1.sub(/\A /, '')
              pending_start_1 ||= i + 1
              i += 1

            elsif stripped.empty?
              # Blank line resets pending comments.
              pending_comments  = []
              pending_start_1   = nil
              i += 1

            elsif stop_at_end && strip_inline_comment(stripped).strip == 'end'
              # End of enclosing block.
              return [statements, i + 1]

            else
              stmt, i = parse_statement(lines, i, pending_comments, pending_start_1)
              statements << stmt if stmt
              pending_comments  = []
              pending_start_1   = nil
            end
          end

          [statements, i]
        end

        def strip_inline_comment(line)
          in_single = false
          in_double = false
          escaped   = false

          line.each_char.with_index do |char, index|
            if escaped
              escaped = false
              next
            end

            case char
            when "\\"
              escaped = true if in_single || in_double
            when "'"
              in_single = !in_single unless in_double
            when '"'
              in_double = !in_double unless in_single
            when '#'
              return line[0...index].rstrip unless in_single || in_double
            end
          end

          line.rstrip
        end

        def sanitized_statement_lines(lines, start_index)
          overrides = { start_index => strip_inline_comment(lines[start_index]) }

          j = start_index + 1
          while j < lines.length && lines[j].lstrip.start_with?('|')
            overrides[j] = strip_inline_comment(lines[j])
            j += 1
          end

          overrides
        end

        # Dispatch a single declaration line.
        def parse_statement(lines, i, comments, comment_start_1)
          sanitized     = sanitized_statement_lines(lines, i)
          stripped      = sanitized.fetch(i, lines[i]).strip
          line_num        = i + 1  # 1-indexed

          docs   = comments.empty? ? nil : comments.join("\n")
          crange = comment_start_1 ? (comment_start_1)..(line_num - 1) : nil

          case stripped
          when /\Aclass\s/
            parse_namespace(:class, lines, i, docs, crange)
          when /\Amodule\s/
            parse_namespace(:module, lines, i, docs, crange)
          when /\Ainterface\s/
            parse_namespace(:interface, lines, i, docs, crange)
          when /\Adef\s/
            parse_method_def(sanitized, lines, i, docs, crange)
          when /\Aattr_reader\s/
            parse_attr(:attr_reader, lines, i, docs, crange)
          when /\Aattr_writer\s/
            parse_attr(:attr_writer, lines, i, docs, crange)
          when /\Aattr_accessor\s/
            parse_attr(:attr_accessor, lines, i, docs, crange)
          when /\A(include|extend|prepend)\s+(\S+)/
            kind = $1.to_sym
            name = $2.delete(';')
            stmt = Statement.new(
              :type           => kind,
              :name           => name,
              :mixin_name     => name,
              :line           => line_num,
              :source         => stripped,
              :comments       => docs,
              :comments_range => crange
            )
            [stmt, i + 1]
          when /\Aalias\s+(\S+)\s+(\S+)/
            stmt = Statement.new(
              :type           => :alias,
              :name           => $1,
              :line           => line_num,
              :source         => stripped,
              :comments       => docs,
              :comments_range => crange
            )
            [stmt, i + 1]
          when /\A(public|private|protected)\s*(\z|#)/
            # Visibility modifier – skip silently.
            [nil, i + 1]
          when /\Aend\s*(\z|#)/
            # Stray `end` – skip.
            [nil, i + 1]
          when /\Atype\s/
            # Type alias declaration – nothing to document.
            [nil, i + 1]
          else
            # Constant declaration: `NAME: Type`
            if stripped =~ /\A([A-Z][a-zA-Z0-9_]*(?:::[A-Z][a-zA-Z0-9_]*)*)\s*:\s*(.+)\z/
              stmt = Statement.new(
                :type           => :constant,
                :name           => $1,
                :attr_rbs_type  => $2.strip,
                :line           => line_num,
                :source         => stripped,
                :comments       => docs,
                :comments_range => crange
              )
              [stmt, i + 1]
            else
              [nil, i + 1]
            end
          end
        end

        def parse_namespace(type, lines, i, docs, crange)
          # Strip trailing inline comment from the declaration line.
          decl     = lines[i].strip.sub(/\s*#.*\z/, '')
          line_num = i + 1

          name       = nil
          superclass = nil

          case type
          when :class
            # class Foo[T] < Bar[String]
            if decl =~ /\Aclass\s+([^\s<\[]+)(\[[^\]]*\])?(?:\s*<\s*(.+))?\z/
              name       = $1.strip
              superclass = $3 ? $3.strip : nil
              # Strip generic params from superclass, e.g. "Array[String]" -> "Array"
              superclass.sub!(/\[.*\]\z/, '') if superclass
            else
              return [nil, i + 1]
            end

          when :module
            # module Foo[T] : SelfType
            if decl =~ /\Amodule\s+([^\s\[(:]+)/
              name = $1.strip
            else
              return [nil, i + 1]
            end

          when :interface
            # interface _Foo[T]
            if decl =~ /\Ainterface\s+([^\s\[]+)/
              name = $1.strip
            else
              return [nil, i + 1]
            end
          end

          children, new_i = parse_body(lines, i + 1, true)
          source = lines[i...new_i].join("\n")

          stmt = Statement.new(
            :type           => type,
            :name           => name,
            :superclass     => superclass,
            :line           => line_num,
            :source         => source,
            :comments       => docs,
            :comments_range => crange,
            :block          => children
          )

          [stmt, new_i]
        end

        def parse_method_def(sanitized, lines, i, docs, crange)
          stripped = sanitized.fetch(i, lines[i]).strip
          line_num = i + 1

          # def method_name: overload1
          #                | overload2
          # Also handles: def self.method_name: ...
          unless stripped =~ /\Adef\s+(self\.)?(\S+?)\s*:\s*(.*)\z/
            return [nil, i + 1]
          end

          is_class_side = !$1.nil?
          meth_name     = $2
          first_sig     = $3.strip

          sigs = [first_sig]
          j    = i + 1

          # Collect `| overload` continuation lines.
          while j < lines.length
            cont = sanitized.fetch(j, lines[j]).strip
            if cont =~ /\A\|\s*(.*)\z/
              sigs << $1.strip
              j += 1
            else
              break
            end
          end

          stmt = Statement.new(
            :type           => :method_def,
            :name           => meth_name,
            :line           => line_num,
            :source         => lines[i...j].join("\n"),
            :comments       => docs,
            :comments_range => crange,
            :signatures     => sigs,
            :visibility     => is_class_side ? :class : :instance
          )

          [stmt, j]
        end

        def parse_attr(type, lines, i, docs, crange)
          stripped = strip_inline_comment(lines[i]).strip
          line_num = i + 1
          keyword  = type.to_s

          # attr_reader [self.] name : Type
          if stripped =~ /\A#{Regexp.escape(keyword)}\s+(self\.)?(\w+)\s*:\s*(.*)\z/
            is_class  = !$1.nil?
            attr_name = $2
            attr_type = $3.strip

            stmt = Statement.new(
              :type           => type,
              :name           => attr_name,
              :attr_rbs_type  => attr_type,
              :line           => line_num,
              :source         => stripped,
              :comments       => docs,
              :comments_range => crange,
              :visibility     => is_class ? :class : :instance
            )
            [stmt, i + 1]
          else
            [nil, i + 1]
          end
        end
      end
    end
  end
end
