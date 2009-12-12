module YARD
  # A documentation string, or "docstring" for short, encapsulates the 
  # comments and metadata, or "tags", of an object. Meta-data is expressed
  # in the form +@tag VALUE+, where VALUE can span over multiple lines as
  # long as they are indented. The following +@example+ tag shows how tags
  # can be indented:
  # 
  #   # @example My example
  #   #   a = "hello world"
  #   #   a.reverse
  #   # @version 1.0
  # 
  # Tags can be nested in a documentation string, though the {Tags::Tag} 
  # itself is responsible for parsing the inner tags.
  class Docstring < String
    # @return [Array<Tags::RefTag>] the list of reference tags
    attr_reader :ref_tags
    
    # @return [CodeObjects::Base] the object that owns the docstring.
    attr_accessor :object
    
    # @return [Range] line range in the {#object}'s file where the docstring was parsed from
    attr_accessor :line_range
    
    # @return [String] the raw documentation (including raw tag text)
    attr_accessor :all

    # Matches a tag at the start of a comment line
    META_MATCH = /^@([a-z_]+)(?:\s+(.*))?$/i
    
    # Creates a new docstring with the raw contents attached to an optional
    # object.
    # 
    # @example
    #   Docstring.new("hello world\n@return Object return", someobj)
    # 
    # @param [String] content the raw comments to be parsed into a docstring
    #   and associated meta-data.
    # @param [CodeObjects::Base] object an object to associate the docstring
    #   with.
    def initialize(content = '', object = nil)
      @object = object
      
      self.all = content
    end
    
    # Replaces the docstring with new raw content. Called by {#all=}.
    # @param [String] content the raw comments to be parsed
    def replace(content)
      @tags, @ref_tags = [], []
      @all = content
      super parse_comments(content)
    end
    alias all= replace
    
    # @return [Fixnum] the first line of the {#line_range}.
    def line
      line_range.first
    end
    
    # Gets the first line of a docstring to the period or the first paragraph.
    # @return [String] The first line or paragraph of the docstring; always ends with a period.
    def summary
      return @summary if @summary
      open_parens = ['{', '(', '[']
      close_parens = ['}', ')', ']']
      num_parens = 0
      idx = length.times do |index|
        case self[index, 1]
        when ".", "\r", "\n"
          next_char = self[index + 1, 1].to_s
          if num_parens == 0 && next_char =~ /^\s*$/
            break index - 1
          end
        when "{", "(", "["
          num_parens += 1
        when "}", ")", "]"
          num_parens -= 1
        end
      end
      @summary = self[0..idx]
      @summary += '.' unless @summary.empty?
      @summary
    end
    
    # Adds a tag or reftag object to the tag list
    # @param [Tags::Tag, Tags::RefTag] tags list of tag objects to add
    def add_tag(*tags)
      tags.each_with_index do |tag, i|
        case tag
        when Tags::Tag
          tag.object = object
          @tags << tag
        when Tags::RefTag
          @ref_tags << tag
        else
          raise ArgumentError, "expected Tag or RefTag, got #{tag.class} (at index #{i})"
        end
      end
    end
    
    # Convenience method to return the first tag
    # object in the list of tag objects of that name
    #
    # @example
    #   doc = Docstring.new("@return zero when nil")
    #   doc.tag(:return).text  # => "zero when nil"
    #
    # @param [#to_s] name the tag name to return data for
    # @return [Tags::Tag] the first tag in the list of {#tags}
    def tag(name)
      tags.find {|tag| tag.tag_name.to_s == name.to_s }
    end

    # Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
    #
    # @param [#to_s] name the tag name to return data for, or nil for all tags
    # @return [Array<Tags::Tag>] the list of tags by the specified tag name
    def tags(name = nil)
      list = @tags + convert_ref_tags
      return list unless name
      list.select {|tag| tag.tag_name.to_s == name.to_s }
    end

    ##
    # Returns true if at least one tag by the name +name+ was declared
    #
    # @param [String] name the tag name to search for
    # @return [Boolean] whether or not the tag +name+ was declared
    def has_tag?(name)
      tags.any? {|tag| tag.tag_name.to_s == name.to_s }
    end

    # Returns true if the docstring has no content
    #
    # @return [Boolean] whether or not the docstring has content
    def blank?
      empty? && @tags.empty? && @ref_tags.empty?
    end

    private
    
    # Maps valid reference tags
    # 
    # @return [Array<Tags::RefTag>] the list of valid reference tags
    def convert_ref_tags
      list = @ref_tags.reject {|t| CodeObjects::Proxy === t.owner }
      list.map {|t| t.tags }.flatten
    end
    
    # Creates a {Tags::RefTag}
    def create_ref_tag(tag_name, name, object)
      @ref_tags << Tags::RefTagList.new(tag_name, object, name)
    end
    
    # Creates a tag from the {Tags::DefaultFactory tag factory}.
    # 
    # @param [String] tag_name the tag name
    # @param [String] tag_buf the text attached to the tag with newlines removed.
    # @param [String] raw_buf the raw buffer of text without removed newlines.
    # @return [Tags::Tag, Tags::RefTag] a tag
    def create_tag(tag_name, tag_buf, raw_buf)
      if tag_buf =~ /\A\s*(?:(\S+)\s+)?\(\s*see\s+(\S+)\s*\)\s*\Z/
        return create_ref_tag(tag_name, $1, $2)
      end
        
      tag_factory = Tags::Library.instance
      tag_method = "#{tag_name}_tag"
      if tag_name && tag_factory.respond_to?(tag_method)
        if tag_factory.method(tag_method).arity == 2
          add_tag *tag_factory.send(tag_method, tag_buf, raw_buf.join("\n"))
        else
          add_tag *tag_factory.send(tag_method, tag_buf) 
        end
      else
        log.warn "Unknown tag @#{tag_name}" + (object ? " in file `#{object.file}` near line #{object.line}" : "")
      end
    rescue Tags::TagFormatError
      log.warn "Invalid tag format for @#{tag_name}" + (object ? " in file `#{object.file}` near line #{object.line}" : "")
    end

    # Parses out comments split by newlines into a new code object
    #
    # @param [String] comments 
    #   the newline delimited array of comments. If the comments
    #   are passed as a String, they will be split by newlines. 
    # 
    # @return [String] the non-metadata portion of the comments to
    #   be used as a docstring
    def parse_comments(comments)
      comments = comments.split(/\r?\n/) if comments.is_a?(String)
      return '' if !comments || comments.empty?
      docstring = ""

      indent, last_indent = comments.first[/^\s*/].length, 0
      orig_indent = 0
      last_line = ""
      tag_name, tag_klass, tag_buf, raw_buf = nil, nil, "", []

      (comments+['']).each_with_index do |line, index|
        indent = line[/^\s*/].length 
        empty = (line =~ /^\s*$/ ? true : false)
        done = comments.size == index

        if tag_name && (((indent < orig_indent && !empty) || done) || 
            (indent <= last_indent && line =~ META_MATCH))
          create_tag(tag_name, tag_buf, raw_buf)
          tag_name, tag_buf, raw_buf = nil, '', []
          orig_indent = 0
        end

        # Found a meta tag
        if line =~ META_MATCH
          orig_indent = indent
          tag_name, tag_buf = $1, ($2 || '')
          raw_buf = [tag_buf.dup]
        elsif tag_name && indent >= orig_indent && !empty
          # Extra data added to the tag on the next line
          last_empty = last_line =~ /^[ \t]*$/ ? true : false
          
          if last_empty
            tag_buf << "\n\n" 
            raw_buf << ''
          end
          
          tag_buf << line.gsub(/^[ \t]{#{indent}}/, last_empty ? '' : ' ')
          raw_buf << line.gsub(/^[ \t]{#{orig_indent}}/, '')
        elsif !tag_name
          # Regular docstring text
          docstring << line << "\n" 
        end

        last_indent = indent
        last_line = line
      end

      # Remove trailing/leading whitespace / newlines
      docstring.gsub!(/\A[\r\n\s]+|[\r\n\s]+\Z/, '')
    end
  end
end
