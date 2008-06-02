require "delegate"

module YARD
  module CodeObjects
    class CodeObjectList < Array
      def initialize(owner = Registry.root)
        @owner = owner
      end
      
      def push(value)
        value = Proxy.new(@owner, value) if value.is_a?(String) || value.is_a?(Symbol)
        if value.is_a?(CodeObjects::Base) || value.is_a?(Proxy)
          super(value) unless include?(value)
        else
          raise ArgumentError, "#{value.class} is not a valid CodeObject"
        end
        self
      end
      alias_method :<<, :push
    end
    
    NSEP = '::'
    ISEP = '#'
    CONSTANTMATCH = /[A-Z]\w*/
    NAMESPACEMATCH = /(?:(?:#{Regexp.quote NSEP})?#{CONSTANTMATCH})+/
    METHODMATCH = /(?:(?:#{NAMESPACEMATCH}|self)\s*(?:\.|#{Regexp.quote NSEP})\s*)?[\w=<>^%&*!~`^\|\?\/\[\]]+/
    
    class Base  
      attr_reader :name
      attr_accessor :namespace
      attr_accessor :source, :signature, :file, :line, :docstring, :dynamic
      
      def dynamic?; @dynamic end
      
      class << self
        def new(namespace, name, *args, &block)
          if name =~ /(?:#{NSEP}|#{ISEP})([^#{NSEP}#{ISEP}]+)$/
            return new(Proxy.new(namespace, $`), $1, *args, &block)
          end
          
          keyname = namespace && namespace.respond_to?(:path) ? namespace.path : ''
          if self == RootObject
            keyname = :root
          elsif keyname.empty?
            keyname = name.to_s
          elsif self == MethodObject
            keyname += (!args.first || args.first.to_sym == :instance ? ISEP : NSEP) + name.to_s
          else
            keyname += NSEP + name.to_s
          end
          
          if self != RootObject && obj = Registry[keyname]
            yield(obj) if block_given?
            obj
          else
            Registry.objects[keyname] = super(namespace, name, *args, &block)
          end
        end
      end
          
      def initialize(namespace, name, *args)
        if namespace && namespace != :root && 
            !namespace.is_a?(NamespaceObject) && !namespace.is_a?(Proxy)
          raise ArgumentError, "Invalid namespace object: #{namespace}"
        end

        @name = name.to_sym
        @tags = []
        @docstring = ""
        self.namespace = namespace
        yield(self) if block_given?
      end
      
      def ==(other)
        if other.is_a?(Proxy)
          path == other.path
        else
          super
        end
      end
      
      def [](key)
        if respond_to?(key)
          send(key)
        else
          instance_variable_get("@#{key}")
        end
      end
      
      def []=(key, value)
        if respond_to?("#{key}=")
          send("#{key}=", value)
        else
          instance_variable_set("@#{key}", value)
        end
      end
      
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /=$/
          self[meth.to_s[0..-2]] = *args
        elsif instance_variable_get("@#{meth}")
          self[meth]
        else
          super
        end
      end

      ##
      # Attaches source code to a code object with an optional file location
      #
      # @param [Parser::Statement, String] statement 
      #   the +Parser::Statement+ holding the source code or the raw source 
      #   as a +String+ for the definition of the code object only (not the block)
      def source=(statement)
        if statement.is_a? Parser::Statement
          src = statement.tokens.to_s
          blk = statement.block ? statement.block.to_s : ""
          if src =~ /^def\s.*[^\)]$/ && blk[0,1] !~ /\r|\n/
            blk = ";" + blk
          end
          
          @source = format_source(src + blk)
          self.line = statement.tokens.first.line_no
          self.signature = src
        else
          @source = format_source(statement.to_s)
        end
      end

      ##
      # Attaches a docstring to a code oject by parsing the comments attached to the statement
      # and filling the {#tags} and {#docstring} methods with the parsed information.
      #
      # @param [String, Array<String>] comments 
      #   the comments attached to the code object to be parsed 
      #   into a docstring and meta tags.
      def docstring=(comments)
        @short_docstring = nil
        parse_comments(comments) if comments
      end
      
      ##
      # Gets the first line of a docstring to the period or the first paragraph.
      # 
      # @return [String] The first line or paragraph of the docstring; always ends with a period.
      def short_docstring
        @short_docstring ||= (docstring.split(/\.|\r?\n\r?\n/).first || '')
        @short_docstring += '.' unless @short_docstring.empty?
      end

      ##
      # Default type is the lowercase class name without the "Object" suffix
      # 
      # Override this method to provide a custom object type 
      # 
      # @return [Symbol] the type of code object this represents
      def type
        self.class.name.split(/#{NSEP}/).last.gsub(/Object$/, '').downcase.to_sym
      end
    
      def path
        if parent && parent != Registry.root
          [parent.path, name.to_s].join(sep)
        else
          name.to_s
        end
      end
      alias_method :to_s, :path
      
      def inspect
        "#<yardoc #{type} #{path}>"
      end
    
      def namespace=(obj)
        if @namespace
          @namespace.children.delete(self) 
          Registry.delete(self)
        end
        
        @namespace = (obj == :root ? Registry.root : obj)
      
        if @namespace
          @namespace.children << self unless @namespace.is_a?(Proxy)
          Registry.register(self)
        end
      end
    
      alias_method :parent, :namespace
      alias_method :parent=, :namespace=

      ## 
      # Convenience method to return the first tag
      # object in the list of tag objects of that name
      #
      # Example:
      #   doc = YARD::Documentation.new("@return zero when nil")
      #   doc.tag("return").text  # => "zero when nil"
      #
      # @param [#to_s] name the tag name to return data for
      # @return [Tags::Tag] the first tag in the list of {#tags}
      def tag(name)
        @tags.find {|tag| tag.tag_name.to_s == name.to_s }
      end

      ##
      # Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
      #
      # @param name the tag name to return data for, or nil for all tags
      # @return [Array<Tags::Tag>] the list of tags by the specified tag name
      def tags(name = nil)
        return @tags if name.nil?
        @tags.select {|tag| tag.tag_name.to_s == name.to_s }
      end

      ##
      # Returns true if at least one tag by the name +name+ was declared
      #
      # @param [String] name the tag name to search for
      # @return [Boolean] whether or not the tag +name+ was declared
      def has_tag?(name)
        @tags.any? {|tag| tag.tag_name.to_s == name.to_s }
      end

      protected
    
      def sep; NSEP end

      private

      ##
      # Parses out comments split by newlines into a new code object
      #
      # @param [Array<String>, String] comments 
      #   the newline delimited array of comments. If the comments
      #   are passed as a String, they will be split by newlines. 
      def parse_comments(comments)
        return if comments.empty?
        meta_match = /^@(\S+)\s*(.*)/
        comments = comments.split(/\r?\n/) if comments.is_a? String
        @tags, @docstring = [], ""

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
            tagfactory = Tags::Library.new
            tag_method = "#{tag_name}_tag"
            if tag_name && tagfactory.respond_to?(tag_method)
              if tagfactory.method(tag_method).arity == 1
                @tags << tagfactory.send(tag_method, tag_buf) 
              else
                @tags << tagfactory.send(tag_method, tag_buf, raw_buf.join("\n"))
              end
            else
              YARD.logger.warn "Unknown tag @#{tag_name} in documentation for `#{path}`"
            end
            tag_name, tag_buf, raw_buf = nil, '', []
            orig_indent = 0
          end

          # Found a meta tag
          if line =~ meta_match
            orig_indent = indent
            tag_name, tag_buf = $1, $2 
          elsif tag_name && indent >= orig_indent && !empty
            # Extra data added to the tag on the next line
            last_empty = last_line =~ /^\s*$/ ? true : false
            
            if last_empty
              tag_buf << "\n\n" 
              raw_buf << ''
            end
            
            tag_buf << line.gsub(/^\s{#{indent}}/, last_empty ? '' : ' ')
            raw_buf << line.gsub(/^\s{#{orig_indent}}/, '')
          elsif !tag_name
            # Regular docstring text
            @docstring << line << "\n" 
          end

          last_indent = indent
          last_line = line
        end

        # Remove trailing/leading whitespace / newlines
        @docstring.gsub!(/\A[\r\n\s]+|[\r\n\s]+\Z/, '')
      end      
      
      # Formats source code by removing leading indentation
      def format_source(source)
        source.chomp!
        indent = source.split(/\r?\n/).last[/^(\s*)/, 1].length
        source.gsub(/^\s{#{indent}}/, '')
      end
    end
  end
end