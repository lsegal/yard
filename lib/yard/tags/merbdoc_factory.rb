module YARD
  module Tags
    class MerbdocFactory < DefaultFactory
      ##
      # Parses tag text and creates a new tag with formally declared types and 
      # descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param text<String>    the raw tag text
      # @return <Tag>          a tag object with the tag_name, types and text values filled
      def parse_tag_with_types(tag_name, text)
        _, types, text = *extract_types_from_text(text)
        # TODO warn if name value ('_') is not nil, because that's invalid syntax
        Tag.new(tag_name, text, types)
      end
      
      ##
      # Parses tag text and creates a new tag with formally declared types, a key 
      # name and descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param text<String>    the raw tag text
      # @return <Tag>          a tag object with the tag_name, name, types and text values filled
      def parse_tag_with_types_and_name(tag_name, text)
        name, types, text = *extract_types_from_text(text)
        name, text = *extract_name_from_text(text) if name.nil?
        Tag.new(tag_name, text, types, name)
      end
      
      private
      
      ##
      # Extracts the type signatures with an optional name from the raw tag text
      #
      # @param text<String> the raw tag text
      # @return <Array> an array holding the name as the first element (nil if empty),
      #                 array of types as the second element and the raw text as the last.
      def extract_types_from_text(text)
        name, types, text = nil, [], text.strip
        if text =~ /^\s*(\S*)\s*<(.+?)>\s*(.*)/
          name, text, types = $1, $3, $2.split(",").collect {|e| e.strip }
        end
        [name, types, text]
      end
    end
  end
end