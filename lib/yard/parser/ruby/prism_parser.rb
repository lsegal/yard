# frozen_string_literal: true

begin
  require 'prism'
rescue LoadError
  nil
end

module YARD
  module Parser
    module Ruby
      # A parser that uses the Prism library to parse Ruby source code.
      class PrismParser
        attr_reader :file, :prism_result
        attr_reader :shebang_line, :encoding_line, :frozen_string_line

        def initialize(source, filename)
          @source = source
          @file = filename
          @tokens = nil
          @shebang_line = nil
          @encoding_line = nil
          @frozen_string_line = nil
        end

        def parse
          @prism_result = result = Prism.parse(@source, filepath: @file, partial_script: true)

          fatal = result.errors.reject { |e| e.type == :write_target_in_method }
          unless fatal.empty?
            error = fatal.first
            raise ParserSyntaxError,
              "syntax error in `#{@file}`:(#{error.location.start_line},#{error.location.start_column}): #{error.message}"
          end

          first_line = result.value.statements.body.first&.location&.start_line
          result.comments.each do |comment|
            next unless comment.is_a?(Prism::InlineComment)
            break if first_line && comment.location.start_line >= first_line

            text = comment.location.slice
            if @shebang_line.nil? && @encoding_line.nil? && text =~ SourceParser::SHEBANG_LINE
              @shebang_line = text
            elsif @encoding_line.nil? && text =~ SourceParser::ENCODING_LINE
              @encoding_line = text
            elsif text =~ SourceParser::FROZEN_STRING_LINE
              @frozen_string_line = text
            else
              break # non-special comment stops recognition
            end
          end

          self
        end

        def enumerator
          @prism_result
        end

        def tokens
          @tokens ||=
            Prism.lex_compat(@source, filepath: @file).value.map do |(pos, type, value, _)|
              [type.to_s.delete_prefix("on_").to_sym, value, pos]
            end
        end
      end if defined?(::Prism)
    end
  end
end
