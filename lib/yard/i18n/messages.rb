module YARD
  module I18n
    # +Messages+ is a container for +Message+s.
    #
    # @since 0.8.1
    class Messages
      include Enumerable

      # Creates a +Message+ container.
      def initialize
        @messages = {}
      end

      # Enumerates each +Message+ in the container.
      #
      # @return [void]
      def each(&block)
        @messages.each_value(&block)
      end

      # Retrieves the registered +Message+, the message ID of which is
      # +id+. If corresponding +Message+ isn't registered, +nil+ is
      # returned.
      #
      # @param [String] id the message ID to be retrieved.
      # @return [Message] the registered +Message+ or +nil+.
      def [](id)
        @messages[id]
      end

      # Registers a +Message+, the mssage ID of which is +id+. If
      # corresponding +Message+ exists in the +Messages+, existent
      # +Message+ is returned.
      #
      # @param [String] id the message ID to be registered.
      # @return [Message] the registered +Message+.
      def register(id)
        @messages[id] ||= Message.new(id)
      end

      # Compares equivalence between +self+ and +other+.
      #
      # @param [Messages] other the +Messages+ to be compared.
      # @return [Boolean] whether +self+ and +other+ is equivalence or not.
      def ==(other)
        other.is_a?(self.class) and
          @messages == other.messages
      end

      protected
      def messages
        @messages
      end
    end
  end
end
