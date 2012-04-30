require 'ostruct'

module YARD
  # @since 0.8.0
  class DocstringParser
    attr_reader :text
    attr_reader :raw_text
    attr_reader :tags
    attr_reader :directives
    attr_reader :state

    attr_accessor :object
    attr_accessor :handler

    attr_accessor :library

    META_MATCH = /^@(!)?((?:\w\.?)+)(?:\s+(.*))?$/i

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

    def to_docstring
      Docstring.new!(text, tags, object, raw_text)
    end

    private

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
