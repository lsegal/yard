require "set"

module YARD
  module I18n
    # +Message+ is a translation target message. It has message ID as
    # {#id} and some properties {#locations} and {#comments}.
    #
    # @since 0.8.1
    class Message
      # The message ID of the trnslation target message.
      #
      # @return [String]
      attr_reader :id

      # The array of locations. Location is an array of path and line
      # number where the message is appered.
      #
      # @return [Set]
      attr_reader :locations

      # The array of comments for the messages.
      #
      # @return [Set]
      attr_reader :comments

      # Creates a trasnlate target message for message ID +id+.
      #
      # @param [String] id the message ID of the translate target message.
      def initialize(id)
        @id = id
        @locations = Set.new
        @comments = Set.new
      end

      # Adds a location where the messasge is appeared.
      #
      # @param [String] path the path where the message is appeared.
      # @param [Integer] line the line number where the message is appeared.
      # @return [void]
      def add_location(path, line)
        @locations << [path, line]
      end

      # Adds a comment for the message.
      #
      # @param [String] comment the comment for the message to be added.
      # @return [void]
      def add_comment(comment)
        @comments << comment unless comment.nil?
      end

      # Compares equivalence between +self+ and +other+.
      #
      # @param [Message] other the +Message+ to be compared.
      # @return [Boolean] whether +self+ and +other+ is equivalence or not.
      def ==(other)
        other.is_a?(self.class) and
          @id == other.id and
          @locations == other.locations and
          @comments == other.comments
      end
    end
  end
end
