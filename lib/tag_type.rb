module YARD
  ## 
  # Represents a tag and its respective tag name and value. 
  #
  # @abstract   Override this class to using the class name format of
  #             'tagnameTag' to add a new tag to the registered tag library
  class BaseTag
    class << self
      ##
      # Returns the tag name that the class responds to. If the class name
      # does not accurately represent the tag name, this method should be overrided
      # by subclasses to return the correct tag name.
      # 
      # @return [String] the tag name the class represents
      def tag_name
        @tag_name ||= self.to_s.split("::").last.gsub(/^Base.+|Tag$/, '').downcase
      end

      ##
      # Return all valid tags in the tag library
      # 
      # @return [Array<String>] a list of valid tags that are registered
      #                         as being handled
      def tag_library
        @@tag_library || {}
      end
    
      ##
      # @override
      def inherited(subclass)
        @@tag_library ||= {}
        @@tag_library[subclass.tag_name] = subclass unless subclass.tag_name.empty?
      end
      
      ##
      # Parses tag text from a doc string and returns a new tag 
      def parse_tag(text)
        new(text)
      end
    end

    ## All tags have an optional field for text data 
    attr_reader :text
    
    def initialize(text)
      @text = text
    end

    ## 
    # @see BaseTag::tag_name
    def tag_name
      self.class.tag_name
    end
  end
  
  ##
  # Similar to the {BaseTag}, this class allows for a tag to
  # formally specify type data if it depends on a specific object type.
  #
  class BaseTypeTag < BaseTag
    ##
    # Attribute reader for all specified types
    #
    # @return [String] the object types that the tag formally specifies
    attr_reader :types
    
    ##
    # Extracts the type signatures from the raw tag text
    #
    # @param [String] text the raw tag text
    # @return [Array] an array holding the value as the first element and
    #                 the array of types as the second element
    def self.extract_types_and_text(text)
      types, value = [], text.strip
      if text =~ /^\s*\[(.+?)\]\s*(.*)/
        value = $2
        types = $1.split(",").collect {|e| e.strip }
      end
      [value, types]
    end
    
    ##
    # Extracts the name from raw tag text returning the name and remaining value
    #
    # @param [String] text the raw tag text
    # @return [Array] an array holding the name as the first element and the 
    #                 value as the second element
    def self.extract_name_and_text(text)
      text.strip.split(" ", 2)
    end
    
    ## 
    # Create a new object with formally specified types
    #
    # @param [String] text the text data
    # @param [Array<String>] types the types that are formally specified
    #                        by the tag.
    def initialize(text, types = [])
      super(text)
      @types = types || []
    end
    
    ##
    # Convenience method to access the first type specified. This should mainly
    # be used for tags that only specify one type.
    #
    # @return (String) the first of the list of specified types 
    def type
      types.first
    end
  end
  
  class ParamTag < BaseTypeTag
    attr_reader :name
    
    ##
    # Parses a typed tag's value section and returns a new {ParamTag} object
    #
    # @param [String] text the raw tag value to parse type specifications from
    # @return [ParamTag] the new typed tag object with the type values 
    #                    parsed from raw text
    def self.parse_tag(text)
      desc, types = *extract_types_and_text(text)
      name, desc = *extract_name_and_text(desc)
      new(name, desc, types)
    end
    
    ##
    # Create a new +param+ tag with a description and declared types
    #
    # @param [String] name the parameter name specified by the tag
    # @param [String] text a description of the parameter 
    # @param [Array<String>] types the optional types that the parameter accepts
    def initialize(name, text, types = [])
      super(text, types)
      @name = name
    end
  end

  class ReturnTag < BaseTypeTag
    def self.parse_tag(text)
      new *extract_types_and_text(text) 
    end
    
    def initialize(text, types = []) super end
  end
  
  class DeprecatedTag < BaseTag
    def initialize(text) super end
  end
  
  class AuthorTag < BaseTag
    def initialize(text) super end
  end  
end