module YARD
  class Docstring < String
    attr_reader :object, :ref_tags
    
    def initialize(content = '', object = nil)
      @tag_factory = Tags::Library.new
      @tags, @ref_tags = [], []
      @object = object
      
      replace parse_comments(content)
    end
    
    ##
    # Gets the first line of a docstring to the period or the first paragraph.
    # 
    # @return [String] The first line or paragraph of the docstring; always ends with a period.
    def summary
      @summmary ||= (split(/\.|\r?\n\r?\n/).first || '')
      @summmary += '.' unless @summmary.empty?
      @summmary
    end
    
    ##
    # Adds a tag or reftag object to the tag list
    # 
    # @param [Tags::Tag, Tags::RefTag] *tags list of tag objects to add
    def add_tag(*tags)
      tags.each_with_index do |tag, i|
        case tag
        when Tags::Tag
          @tags << tag
        when Tags::RefTag
          @ref_tags << tag
        else
          raise ArgumentError, "expected Tag or RefTag, got #{tag.class} (at index #{i})"
        end
      end
    end
    
    ## 
    # Convenience method to return the first tag
    # object in the list of tag objects of that name
    #
    # @example
    #   doc = YARD::Docstring.new("@return zero when nil")
    #   doc.tag(:return).text  # => "zero when nil"
    #
    # @param [#to_s] name the tag name to return data for
    # @return [Tags::Tag] the first tag in the list of {#tags}
    def tag(name)
      tags.find {|tag| tag.tag_name.to_s == name.to_s }
    end

    ##
    # Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
    #
    # @param name the tag name to return data for, or nil for all tags
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

    private
    
    def convert_ref_tags
      list = @ref_tags.reject {|t| CodeObjects::Proxy === t.owner }
      list.map {|t| t.tags }.flatten
    end
    
    ##
    # Creates a {RefTag}
    def create_ref_tag(tag_name, name, object)
      @ref_tags << Tags::RefTagList.new(tag_name, object, name)
    end
    
    ##
    # Creates a tag from the TagFactory 
    # 
    def create_tag(tag_name, tag_buf, raw_buf)
      if tag_buf =~ /\A\s*(?:(\S+)\s+)?\(\s*see\s+(\S+)\s*\)\s*\Z/
        return create_ref_tag(tag_name, $1, $2)
      end
        
      tag_method = "#{tag_name}_tag"
      if tag_name && @tag_factory.respond_to?(tag_method)
        if @tag_factory.method(tag_method).arity == 2
          @tags.push *@tag_factory.send(tag_method, tag_buf, raw_buf.join("\n"))
        else
          @tags.push *@tag_factory.send(tag_method, tag_buf) 
        end
      else
        log.warn "Unknown tag @#{tag_name}" + (object ? " in file `#{object.file}` near line #{object.line}" : "")
      end
    rescue Tags::TagFormatError
      log.warn "Invalid tag format for @#{tag_name}" + (object ? " in file `#{object.file}` near line #{object.line}" : "")
    end

    ##
    # Parses out comments split by newlines into a new code object
    #
    # @param [String] comments 
    #   the newline delimited array of comments. If the comments
    #   are passed as a String, they will be split by newlines. 
    # 
    # @return [String] the non-metadata portion of the comments to
    #   be used as a docstring
    def parse_comments(comments)
      return '' if !comments || comments.empty?
      meta_match = /^@(\S+)\s*(.*)/
      comments = comments.split(/\r?\n/) if comments.is_a? String
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
            (indent <= last_indent && line =~ meta_match))
          create_tag(tag_name, tag_buf, raw_buf)
          tag_name, tag_buf, raw_buf = nil, '', []
          orig_indent = 0
        end

        # Found a meta tag
        if line =~ meta_match
          orig_indent = indent
          tag_name, tag_buf = $1, $2 
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