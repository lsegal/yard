module YARD
  ##
  # Holds all the registered meta tags. If you want to extend YARD and add
  # a new meta tag, you can do it in one of two ways.
  #
  # == Method #1
  # Write your own +tagname_tag+ method that takes the raw text as a parameter.
  # Example:
  #   def mytag_tag(text)
  #     Tag.parse_tag("mytag", text)
  #   end
  #
  # This will allow you to use @mytag TEXT to add meta data to classes through
  # the docstring. {Tag} has a few convenience factory methods to create 
  #
  # == Method #2
  # Use {TagLibrary::define_tag!} to define a new tag by passing the tag name
  # and the factory method to use when creating the tag. These definitions will
  # be auto expanded into ruby code similar to what is shown in method #1. If you
  # do not provide a factory method to use, it will default to {Tag::parse_tag}
  # Example:
  #   define_tag! :param, :with_types_and_name
  #   define_tag! :author
  #
  # The first line will expand to the code:
  #   def param_tag(text) Tag.parse_tag_with_types_and_name(text) end
  #
  # The second line will expand to:
  #   def author_tag(text) Tag.parse_tag(text) end
  #
  # @see TagLibrary::define_tag!
  module TagLibrary
    class << self
      ##
      # Convenience method to define a new tag using one of {Tag}'s factory methods, or the
      # regular {Tag::parse_tag} factory method if none is supplied.
      #
      # @param tag the tag name to create
      # @param meth the {Tag} factory method to call when creating the tag
      def self.define_tag!(tag, meth = "")
        meth = meth.to_s
        send_name = meth.empty? ? "" : "_" + meth
        class_eval "def #{tag}_tag(text) Tag.parse_tag#{send_name}(#{tag.inspect}, text) end"
      end
      
      define_tag! :param, :with_types_and_name
      define_tag! :yieldparam, :with_types_and_name
      define_tag! :yield
      define_tag! :return, :with_types
      define_tag! :deprecated
      define_tag! :author
      define_tag! :raise, :with_name
      define_tag! :see
      define_tag! :since
      define_tag! :version
    end
  end
  
  class Tag
    attr_reader :tag_name, :text, :types, :name
    
    class << self
      ##
      # Parses tag text and creates a new tag with descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param [String] text   the raw tag text
      # @return [Tag]          a tag object with the tag_name and text values filled
      def parse_tag(tag_name, text)
        new(tag_name, text)
      end
      
      ##
      # Parses tag text and creates a new tag with a key name and descriptive text
      #
      # @param tag_name        the name of the tag to parse
      # @param [String] text   the raw tag text
      # @return [Tag]          a tag object with the tag_name, name and text values filled
      def parse_tag_with_name(tag_name, text)
        name, text = *extract_name_from_text(text)
        new(tag_name, text, nil, name)
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
        new(tag_name, text, types)
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
        new(tag_name, text, types, name)
      end
      
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
    # @param [String] text           the descriptive text for this tag
    # @param [Array<String>] types   optional type list of formally declared types
    #                                for the tag
    # @param [String] name           optional key name which the tag refers to
    def initialize(tag_name, text, types = nil, name = nil)
      @tag_name, @text, @types, @name = tag_name.to_s, text, types, name
    end
    
    ##
    # Convenience method to access the first type specified. This should mainly
    # be used for tags that only specify one type.
    #
    # @see #types
    # @return (String) the first of the list of specified types 
    def type
      types.first
    end
  end
end