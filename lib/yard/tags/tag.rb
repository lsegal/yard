module YARD
  module Tags
    class Tag
      attr_reader :tag_name, :text, :types, :name

      class << self
        ##
        # Parses tag text and creates a new tag with descriptive text
        #
        # @param tag_name        the name of the tag to parse
        # @param text<String>    the raw tag text
        # @return <Tag>          a tag object with the tag_name and text values filled
        def parse_tag(tag_name, text)
          new(tag_name, text)
        end

        ##
        # Parses tag text and creates a new tag with a key name and descriptive text
        #
        # @param tag_name        the name of the tag to parse
        # @param text<String>    the raw tag text
        # @return <Tag>          a tag object with the tag_name, name and text values filled
        def parse_tag_with_name(tag_name, text)
          name, text = *extract_name_from_text(text)
          new(tag_name, text, nil, name)
        end

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
          new(tag_name, text, types)
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
          new(tag_name, text, types, name)
        end

        ##
        # Extracts the name from raw tag text returning the name and remaining value
        #
        # @param text<String> the raw tag text
        # @return <Array> an array holding the name as the first element and the 
        #                 value as the second element
        def extract_name_from_text(text)
          text.strip.split(" ", 2)
        end

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

      ##
      # Creates a new tag object with a tag name and text. Optionally, formally declared types
      # and a key name can be specified.
      #
      # Types are mainly for meta tags that rely on type information, such as +param+, +return+, etc.
      # 
      # Key names are for tags that declare meta data for a specific key or name, such as +param+,
      # +raise+, etc.
      #
      # @param tag_name                the tag name to create the tag for
      # @param text  <String>          the descriptive text for this tag
      # @param types <Array[String]>   optional type list of formally declared types
      #                                for the tag
      # @param name <String>           optional key name which the tag refers to
      def initialize(tag_name, text, types = nil, name = nil)
        @tag_name, @text, @name, @types = tag_name.to_s, text, name, types
      end

      ##
      # Convenience method to access the first type specified. This should mainly
      # be used for tags that only specify one type.
      #
      # @see #types
      # @return <String> the first of the list of specified types 
      def type
        types.first
      end
    end
  end
end