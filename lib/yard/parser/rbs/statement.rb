# frozen_string_literal: true
module YARD
  module Parser
    module RBS
      # Represents a single parsed declaration from an RBS file.
      # Each Statement may have a block of child statements for
      # namespace declarations (class, module, interface).
      class Statement
        # @return [Symbol] declaration type:
        #   :class, :module, :interface, :method_def,
        #   :attr_reader, :attr_writer, :attr_accessor,
        #   :include, :extend, :prepend, :constant, :alias
        attr_reader :type

        # @return [String] the declaration name
        attr_reader :name

        # @return [String, nil] the superclass name (for :class)
        attr_reader :superclass

        # @return [Integer] 1-indexed line number of this statement
        attr_reader :line

        # @return [String] raw source text of the statement
        attr_reader :source

        # @return [String, nil] adjacent comment text (the docstring)
        attr_reader :comments

        # @return [Range, nil] line range of the preceding comments
        attr_reader :comments_range

        # @return [false] RBS files don't use ## hash-flag comments
        attr_reader :comments_hash_flag

        # @return [Array<Statement>] child statements for namespace blocks
        attr_reader :block

        # @return [Array<String>] RBS type signature strings for :method_def
        #   Each element is one overload (e.g. "(String name) -> Integer")
        attr_reader :signatures

        # @return [String, nil] mixin name for :include/:extend/:prepend
        attr_reader :mixin_name

        # @return [String, nil] aliased method name for :alias
        attr_reader :old_name

        # @return [String, nil] RBS type annotation for attrs and constants
        attr_reader :attr_rbs_type

        # @return [Symbol, nil] :class or :instance scope hint from parser
        attr_reader :visibility

        def initialize(attrs = {})
          @type              = attrs[:type]
          @name              = attrs[:name]
          @superclass        = attrs[:superclass]
          @line              = attrs[:line] || 1
          @source            = attrs[:source] || ''
          @comments          = attrs[:comments]
          @comments_range    = attrs[:comments_range]
          @comments_hash_flag = false
          @block             = attrs[:block] || []
          @signatures        = attrs[:signatures] || []
          @mixin_name        = attrs[:mixin_name]
          @old_name          = attrs[:old_name]
          @attr_rbs_type     = attrs[:attr_rbs_type]
          @visibility        = attrs[:visibility]
        end

        # @return [String] a textual snippet used in error messages
        def show
          source
        end
      end
    end
  end
end
