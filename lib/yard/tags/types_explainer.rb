# frozen_string_literal: true
require 'strscan'

module YARD
  module Tags
    class TypesExplainer
      # (see Tag#explain_types)
      # @param types [Array<String>] a list of types to parse and summarize
      def self.explain(*types)
        explain!(*types)
      rescue SyntaxError
        nil
      end

      # (see explain)
      # @raise [SyntaxError] if the types are not parsable
      def self.explain!(*types)
        Parser.parse(types.join(", ")).join("; ")
      end

      class << self
        private :new
      end

      # @private
      class Type
        attr_accessor :name

        def initialize(name)
          @name = name
        end

        def to_s(singular = true)
          if name[0, 1] =~ /[A-Z]/
            singular ? "a#{name[0, 1] =~ /[aeiou]/i ? 'n' : ''} " + name : "#{name}#{name[-1, 1] =~ /[A-Z]/ ? "'" : ''}s"
          else
            name
          end
        end

        protected

        def list_join(list)
          index = 0
          list.inject(String.new) do |acc, el|
            acc << el.to_s
            acc << ", " if index < list.size - 2
            acc << " or " if index == list.size - 2
            index += 1
            acc
          end
        end
      end

      # @private
      class LiteralType < Type
        def to_s(_singular = true)
          "a literal value #{name}"
        end
      end

      # @private
      class DuckType < Type
        def to_s(singular = true)
          singular ? "an object that responds to #{name}" : "objects that respond to #{name}"
        end
      end

      # @private
      class CollectionType < Type
        attr_accessor :types

        def initialize(name, types)
          @name = name
          @types = types
        end

        def to_s(_singular = true)
          "a#{name[0, 1] =~ /[aeiou]/i ? 'n' : ''} #{name} of (" + list_join(types.map {|t| t.to_s(false) }) + ")"
        end
      end

      # @private
      class FixedCollectionType < CollectionType
        def to_s(_singular = true)
          "a#{name[0, 1] =~ /[aeiou]/i ? 'n' : ''} #{name} containing (" + types.map(&:to_s).join(" followed by ") + ")"
        end
      end

      # @private
      class HashCollectionType < Type
        attr_accessor :key_value_pairs

        def initialize(name, key_types_or_pairs, value_types = nil)
          @name = name

          if value_types.nil?
            # New signature: (name, key_value_pairs)
            @key_value_pairs = key_types_or_pairs || []
          else
            # Old signature: (name, key_types, value_types)
            @key_value_pairs = [[key_types_or_pairs, value_types]]
          end
        end

        # Backward compatibility accessors
        def key_types
          return [] if @key_value_pairs.empty?
          @key_value_pairs.first[0] || []
        end

        def key_types=(types)
          if @key_value_pairs.empty?
            @key_value_pairs = [[types, []]]
          else
            @key_value_pairs[0][0] = types
          end
        end

        def value_types
          return [] if @key_value_pairs.empty?
          @key_value_pairs.first[1] || []
        end

        def value_types=(types)
          if @key_value_pairs.empty?
            @key_value_pairs = [[[], types]]
          else
            @key_value_pairs[0][1] = types
          end
        end

        def to_s(_singular = true)
          return "a#{name[0, 1] =~ /[aeiou]/i ? 'n' : ''} #{name}" if @key_value_pairs.empty?

          result = "a#{name[0, 1] =~ /[aeiou]/i ? 'n' : ''} #{name} with "
          parts = @key_value_pairs.map do |keys, values|
            "keys made of (" + list_join(keys.map {|t| t.to_s(false) }) +
            ") and values of (" + list_join(values.map {|t| t.to_s(false) }) + ")"
          end
          result + parts.join(" and ")
        end
      end

      # @private
      class Parser
        include CodeObjects

        TOKENS = {
          :collection_start => /</,
          :collection_end => />/,
          :fixed_collection_start => /\(/,
          :fixed_collection_end => /\)/,
          :type_name => /#{ISEP}#{METHODNAMEMATCH}|#{NAMESPACEMATCH}|#{LITERALMATCH}|\w+/,
          :type_next => /[,]/,
          :whitespace => /\s+/,
          :hash_collection_start => /\{/,
          :hash_collection_value => /=>/,
          :hash_collection_value_end => /;/,
          :hash_collection_end => /\}/,
          # :symbol_start => /:/,
          :parse_end => nil
        }

        def self.parse(string)
          new(string).parse
        end

        def initialize(string)
          @scanner = StringScanner.new(string)
        end

        # @return [Array(Boolean, Array<Type>)] - finished, types
        def parse(until_tokens: [:parse_end])
          current_parsed_types = []
          type = nil
          name = nil
          finished = false
          parse_with_handlers do |token_type, token|
            case token_type
            when *until_tokens
              raise SyntaxError, "expecting name, got '#{token}'" if name.nil?
              type = create_type(name) unless type
              current_parsed_types << type
              finished = true
            when :type_name
              raise SyntaxError, "expecting END, got name '#{token}'" if name
              name = token
            when :type_next
              raise SyntaxError, "expecting name, got '#{token}' at #{@scanner.pos}" if name.nil?
              type = create_type(name) unless type
              current_parsed_types << type
              name = nil
              type = nil
            when :fixed_collection_start, :collection_start
              name ||= "Array"
              klass = token_type == :collection_start ? CollectionType : FixedCollectionType
              type = klass.new(name, parse(until_tokens: [:fixed_collection_end, :collection_end, :parse_end]))
            when :hash_collection_start
              name ||= "Hash"
              type = parse_hash_collection(name)
            end

            [finished, current_parsed_types]
          end
        end

        private

        # @return [Array<Type>]
        def parse_with_handlers
          loop do
            found = false
            TOKENS.each do |token_type, match|
              # TODO: cleanup this code.
              # rubocop:disable Lint/AssignmentInCondition
              next unless (match.nil? && @scanner.eos?) || (match && token = @scanner.scan(match))
              found = true
              # @type [Array<Type>]
              finished, types = yield(token_type, token)
              return types if finished
              break
            end
            raise SyntaxError, "invalid character at #{@scanner.peek(1)}" unless found
          end
          nil
        end

        def parse_hash_collection(name)
          key_value_pairs = []
          current_keys = []
          finished = false

          parse_with_handlers do |token_type, token|
            case token_type
            when :type_name
              current_keys << create_type(token)
            when :type_next
              # Comma - continue collecting keys unless we just processed a value
              # In that case, start a new key group
            when :hash_collection_value
              # => - current keys map to the next value(s)
              raise SyntaxError, "no keys before =>" if current_keys.empty?
              values = parse(until_tokens: [:hash_collection_value_end, :parse_end])
              key_value_pairs << [current_keys, values]
              current_keys = []
            when :hash_collection_end, :parse_end
              # End of hash
              finished = true
            when :whitespace
              # Ignore whitespace
            end

            [finished, HashCollectionType.new(name, key_value_pairs)]
          end
        end

        private

        def create_type(name)
          if name[0, 1] == ":" || (name[0, 1] =~ /['"]/ && name[-1, 1] =~ /['"]/)
            LiteralType.new(name)
          elsif name[0, 1] == "#"
            DuckType.new(name)
          else
            Type.new(name)
          end
        end
      end
    end
  end
end
