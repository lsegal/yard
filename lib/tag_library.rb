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
      attr_reader :labels
      
      ## 
      # Sorts the labels lexically by their label name, often used when displaying
      # the tags.
      # 
      # @return <Array[Symbol],String> the sorted labels as an array of the tag name and label
      def sorted_labels
        labels.sort_by {|a| a.last }
      end
      
      ##
      # Convenience method to define a new tag using one of {Tag}'s factory methods, or the
      # regular {Tag::parse_tag} factory method if none is supplied.
      #
      # @param tag<#to_s> the tag name to create
      # @param meth the {Tag} factory method to call when creating the tag
      def self.define_tag!(label, tag, meth = "")
        meth = meth.to_s
        send_name = meth.empty? ? "" : "_" + meth
        class_eval "def #{tag}_tag(text) Tag.parse_tag#{send_name}(#{tag.inspect}, text) end"
        @labels ||= {}
        @labels.update(tag => label)
      end
      
      define_tag! "Parameters",       :param,       :with_types_and_name
      define_tag! "Block Parameters", :yieldparam,  :with_types_and_name
      define_tag! "Yields",           :yield
      define_tag! "Returns",          :return,      :with_types
      define_tag! "Deprecated",       :deprecated
      define_tag! "Author",           :author
      define_tag! "Raises",           :raise,       :with_name
      define_tag! "See Also",         :see
      define_tag! "Since",            :since
      define_tag! "Version",          :version
    end
  end
  
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