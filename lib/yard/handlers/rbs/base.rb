# frozen_string_literal: true

module YARD
  module Handlers
    module RBS
      class Base < Handlers::Base
        class << self
          # @group Testing for a Handler

          # @return [Boolean] whether or not the statement should be
          #   handled by this handler
          def handles?(node)
            handlers.any? do |a_handler|
              node.is_a?(a_handler)
            end
          end
        end

        # @group Parsing an Inner Block

        def parse_block(stmt, opts = {})
          push_state(opts) do
            nodes = []
            nodes += stmt.each_decl.to_a if stmt.respond_to?(:each_decl)
            nodes += stmt.each_member.to_a if stmt.respond_to?(:each_member)
            nodes += stmt.each_mixin.to_a if stmt.respond_to?(:each_mixin)

            parser.process(nodes)
          end
        end

        # @endgroup

        def register_file_info(object, file = parser.file, line = statement.location.start_line, comments = statement.comment ? statement.comment.string : nil)
          super
        end

        def register_docstring(object, docstring = statement.comment ? statement.comment.string : nil, stmt = statement)
          super
        end

        def register_source(object, source = statement, type = parser.parser_type)
          # do nothing
        end
      end
    end
  end
end
