require 'ostruct'

module YARD
  # Parses text and creates a {Docstring} object to represent documentation
  # for a {CodeObjects::Base}. To create a new docstring, you should initialize
  # the parser and call {#parse} followed by {#to_docstring}.
  #
  # @example Creating a Docstring with a DocstringParser
  #   DocstringParser.new.parse("text here").to_docstring
  # @since 0.8.0
  class DocstringParser
    # @return [String] the parsed text portion of the docstring,
    #   with tags removed.
    attr_reader :text

    # @return [String] the complete input string to the parser.
    attr_reader :raw_text

    # @return [Array<Tag>] the list of meta-data tags identified
    #   by the parser
    attr_reader :tags

    # @return [Array<Directive>] a list of directives identified
    #   by the parser. This list will not be passed on to the
    #   Docstring object.
    attr_reader :directives

    # @return [OpenStruct] any arbitrary state to be passed between
    #   tags during parsing. Mainly used by directives to coordinate
    #   behaviour (so that directives can be aware of other directives
    #   used in a docstring).
    attr_reader :state

    # @return [CodeObjects::Base, nil] the object associated with
    #   the docstring being parsed. May be nil if the docstring is
    #   not attached to any object.
    attr_accessor :object

    # @return [Handlers::Base, nil] the handler parsing this
    #   docstring. May be nil if this docstring parser is not
    #   initialized through
    attr_accessor :handler

    # @return [Tags::Library] the tag library being used to
    #   identify registered tags in the docstring.
    attr_accessor :library

    # The regular expression to match the tag syntax
    META_MATCH = /^@(!)?((?:\w\.?)+)(?:\s+(.*))?$/i

    # Creates a new parser to parse docstring data
    #
    # @param [Tags::Library] library a tag library for recognizing
    #   tags.
    def initialize(library = Tags::Library.instance)
      @text = ""
      @raw_text = ""
      @tags = []
      @directives = []
      @library = library
      @object = nil
      @handler = nil
      @state = OpenStruct.new
    end

    # Parses all content and returns itself.
    #
    # @param [String] content the docstring text to parse
    # @param [CodeObjects::Base] object the object that the docstring
    #   is attached to. Will be passed to directives to act on
    #   this object.
    # @param [Handlers::Base, nil] handler the handler object that is
    #   parsing this object. May be nil if this parser is not being
    #   called from a {Parser::SourceParser} context.
    # @return [self] the parser object. To get the docstring,
    #   call {#to_docstring}.
    # @see #to_docstring
    def parse(content, object = nil, handler = nil)
      @object = object
      @handler = handler
      @raw_text = content
      text = parse_content(content)
      # Remove trailing/leading whitespace / newlines
      @text = text.gsub(/\A[\r\n\s]+|[\r\n\s]+\Z/, '')
      call_directives_after_parse
      self
    end

    # @return [Docstring] translates parsed text into
    #   a Docstring object.
    def to_docstring
      Docstring.new!(text, tags, object, raw_text)
    end

    private

    # Parses all text and tags
    def parse_content(content)
      content = content.split(/\r?\n/) if content.is_a?(String)
      return '' if !content || content.empty?
      docstring = ""

      indent, last_indent = content.first[/^\s*/].length, 0
      orig_indent = 0
      directive = false
      last_line = ""
      tag_name, tag_klass, tag_buf = nil, nil, []

      (content+['']).each_with_index do |line, index|
        indent = line[/^\s*/].length
        empty = (line =~ /^\s*$/ ? true : false)
        done = content.size == index

        if tag_name && (((indent < orig_indent && !empty) || done ||
            (indent == 0 && !empty)) || (indent <= last_indent && line =~ META_MATCH))
          buf = tag_buf.join("\n")
          if directive || tag_is_directive?(tag_name)
            directive = create_directive(tag_name, buf)
            if directive
              docstring << parse_content(directive.expanded_text).chomp
            end
          else
            create_tag(tag_name, buf)
          end
          tag_name, tag_buf, directive = nil, [], false
          orig_indent = 0
        end

        # Found a meta tag
        if line =~ META_MATCH
          directive, tag_name, tag_buf = $1, $2, [($3 || '')]
        elsif tag_name && indent >= orig_indent && !empty
          orig_indent = indent if orig_indent == 0
          # Extra data added to the tag on the next line
          last_empty = last_line =~ /^[ \t]*$/ ? true : false

          tag_buf << '' if last_empty
          tag_buf << line.gsub(/^[ \t]{#{orig_indent}}/, '')
        elsif !tag_name
          # Regular docstring text
          docstring << line << "\n"
        end

        last_indent = indent
        last_line = line
      end

      docstring
    end

    private

    # Creates a tag from the {Tags::DefaultFactory tag factory}.
    #
    # To add an already created tag object, use {#add_tag}
    #
    # @param [String] tag_name the tag name
    # @param [String] tag_buf the text attached to the tag with newlines removed.
    # @return [Tags::Tag, Tags::RefTag] a tag
    def create_tag(tag_name, tag_buf)
      if tag_buf =~ /\A\s*(?:(\S+)\s+)?\(\s*see\s+(\S+)\s*\)\s*\Z/
        return create_ref_tag(tag_name, $1, $2)
      end

      if library.has_tag?(tag_name)
        @tags += [library.tag_create(tag_name, tag_buf)].flatten
      else
        log.warn "Unknown tag @#{tag_name}" +
          (object ? " in file `#{object.file}` near line #{object.line}" : "")
      end
    rescue Tags::TagFormatError
      log.warn "Invalid tag format for @#{tag_name}" +
        (object ? " in file `#{object.file}` near line #{object.line}" : "")
    end

    # Creates a {Tags::RefTag}
    def create_ref_tag(tag_name, name, object_name)
      @tags << Tags::RefTagList.new(tag_name, P(object, object_name), name)
    end

    # Creates a new directive using the registered {#library}
    # @return [Directive] the directive object that is created
    def create_directive(tag_name, tag_buf)
      if library.has_directive?(tag_name)
        dir = library.directive_create(tag_name, tag_buf, self)
        if dir.is_a?(Tags::Directive)
          @directives << dir
          dir
        end
      else
        log.warn "Unknown directive @!#{tag_name}" +
          (object ? " in file `#{object.file}` near line #{object.line}" : "")
        nil
      end
    rescue Tags::TagFormatError
      log.warn "Invalid directive format for @!#{tag_name}" +
        (object ? " in file `#{object.file}` near line #{object.line}" : "")
      nil
    end

    # Calls the {Directive#after_parse} callback on all the
    # created directives.
    def call_directives_after_parse
      directives.each do |dir|
        dir.after_parse
      end
    end

    # Backward compatibility to detect old tags that should be specified
    # as directives in 0.8 and onward.
    def tag_is_directive?(tag_name)
      list = %w(attribute endgroup group macro method scope visibility)
      list.include?(tag_name)
    end
  end
end
