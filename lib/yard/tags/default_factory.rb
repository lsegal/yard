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
      
      def parse_tag_with_raw_text(tag_name, text, raw_text)
        Tag.new(tag_name, raw_text)
      end
      
      def parse_tag_with_raw_title_and_text(tag_name, text, raw_text)
        title, desc = *extract_title_and_desc_from_raw_text(raw_text)
        Tag.new(tag_name, desc, nil, title)
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
      
      def extract_title_and_desc_from_raw_text(raw_text)
        title, desc = nil, nil
        if raw_text =~ /\A[ \t]\n/
          desc = raw_text
        else
          raw_text = raw_text.split(/\r?\n/)
          title = raw_text.shift.squeeze(' ').strip
          desc = raw_text.join("\n")
        end
        [title, desc]
      end
      
      # Parses a [], <>, {} or () block at the beginning of a line of text into a list of
      # comma delimited values.
      # 
      # @example
      #   obj.parse_types('[String, Array<Hash, String>, nil]') # => ['String', 'Array<Hash, String>', 'nil']
      # 
      # @return [Array<String>] The type list separated by commas from the first '[' to the last ']' 
      # @return [nil] If no type list is present.
      def parse_types(text)
        list, level = [''], 0
        text.split(//).each_with_index do |c, i|
          if c =~ /[\[\{\(\<]/ 
            list.last << c if level > 0
            level += 1
          elsif c =~ /[\]\}\)\>]/
            level -= 1 unless list.last[-1,1] == '='
            break if level == 0
            list.last << c
          elsif c == ',' && level == 1
            list.push ''
          elsif c =~ /\S/ && level == 0
            break
          elsif level >= 1
            list.last << c
          end
        end

        if list.size == 1 && list.first == ''
          nil
        else
          list.map {|s| s.strip }
        end
      end
    end
  end
end