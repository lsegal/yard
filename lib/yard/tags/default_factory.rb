module YARD
  module Tags
    class DefaultFactory
      ##
      # Parses tag text and creates a new tag with descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param [String] text   the raw tag text
      # @return [Tag]          a tag object with the tag_name and text values filled
      def parse_tag(tag_name, text)
        Tag.new(tag_name, text)
      end
      
      ##
      # Parses tag text and creates a new tag with a key name and descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param [String] text   the raw tag text
      # @return [Tag]          a tag object with the tag_name, name and text values filled
      def parse_tag_with_name(tag_name, text)
        name, text = *extract_name_from_text(text)
        Tag.new(tag_name, text, nil, name)
      end
      
      ##
      # Parses tag text and creates a new tag with formally declared types and 
      # descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param [String] text   the raw tag text
      # @return [Tag]          a tag object with the tag_name, types and text values filled
      def parse_tag_with_types(tag_name, text)
        types, text = *extract_types_from_text(text)
        Tag.new(tag_name, text, types)
      end
      
      ##
      # Parses tag text and creates a new tag with formally declared types, a key 
      # name and descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param [String] text   the raw tag text
      # @return [Tag]          a tag object with the tag_name, name, types and text values filled
      def parse_tag_with_types_and_name(tag_name, text)
        types, text = *extract_types_from_text(text)
        name, text = *extract_name_from_text(text)
        Tag.new(tag_name, text, types, name)
      end
      
      private
      
      ##
      # Extracts the name from raw tag text returning the name and remaining value
      #
      # @param [String] text the raw tag text
      # @return [Array] an array holding the name as the first element and the 
      #                 value as the second element
      def extract_name_from_text(text)
        text.strip.split(" ", 2)
      end
      
      ##
      # Extracts the type signatures from the raw tag text
      #
      # @param [String] text the raw tag text
      # @return [Array] an array holding the value as the first element and
      #                 the array of types as the second element
      def extract_types_from_text(text)
        types, text = [], text.strip
        if text =~ /^\s*\[(.+?)\]\s*(.*)/
          text, types = $2, $1.split(",").collect {|e| e.strip }
        end
        [types, text]
      end
    end
  end
end