module YARD
  module CodeObjects
    class CodeObjectList < Array
      def initialize(owner)
        @owner = owner
      end
      
      def <<(value)
        if value.is_a? CodeObjects::Base
          super unless include?(value)
        elsif value.is_a?(String) || value.is_a?(Symbol)
          super P(@owner, value) unless include?(P(@owner, value))
        else
          raise ArgumentError, "#{value.class} is not a valid CodeObject"
        end
        self
      end
      
      def push(value)
        self << value
      end
      
      undef :unshift
    end
    
    NSEP = '::'
    ISEP = '#'
    
    class Base  
      attr_reader :name
      attr_accessor :namespace
      attr_accessor :source, :file, :line, :docstring
      attr_reader :tags
      
      class << self
        attr_accessor :instances
        
        def new(namespace, name, *args, &block)
          if name =~ /(?:#{NSEP}|#{ISEP})([^#{NSEP}#{ISEP}]+)$/
            return new(Registry.resolve(namespace, $`, true), $1, *args, &block)
          end
          
          self.instances ||= {}
          keyname = "#{namespace && namespace.respond_to?(:path) ? namespace.path : ''}+#{name.inspect}"
          if obj = Registry.objects[keyname]
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

      ##
      # Attaches source code to a code object with an optional file location
      #
      # @param [Parser::Statement, String] statement 
      #   the +Parser::Statement+ holding the source code or the raw source 
      #   as a +String+ for the definition of the code object only (not the block)
      def source=(statement)
        if statement.is_a? Parser::Statement
          @source = statement.tokens.to_s + (statement.block ? statement.block.to_s : "")
          self.line = statement.tokens.first.line_no
        else
          @source = statement.to_s
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
        parse_comments(comments) if comments
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
      # @return [BaseTag] the first tag in the list of {#tags}
      def tag(name)
        name = name.to_s
        @tags.find {|tag| tag.tag_name == name }
      end

      ##
      # Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
      #
      # @param name the tag name to return data for, or nil for all tags
      # @return [Array<BaseTag>] the list of tags by the specified tag name
      def tags(name = nil)
        return @tags if name.nil?
        name = name.to_s
        @tags.select {|tag| tag.tag_name == name }
      end

      ##
      # Returns true if at least one tag by the name +name+ was declared
      #
      # @param [String] name the tag name to search for
      # @return [Boolean] whether or not the tag +name+ was declared
      def has_tag?(name)
        name = name.to_s
        @tags.any? {|tag| tag.tag_name == name }
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
        meta_match = /^\s*@(\S+)\s*(.*)/
        comments = comments.split(/\r?\n/) if comments.is_a? String
        @tags, @docstring = [], ""

        indent, last_indent = comments.first[/^\s*/].length, 0
        tag_name, tag_klass, tag_buf = nil, nil, ""

        # Add an extra line to catch a meta directive on the last line
        (comments+['']).each do |line|
          indent = line[/^\s*/].length 

          if (indent < last_indent && tag_name) || line == '' || line =~ meta_match
            tag_method = "#{tag_name}_tag"
            if tag_name && TagLibrary.respond_to?(tag_method)
              @tags << TagLibrary.send(tag_method, tag_buf.squeeze(" ")) 
            end
            tag_name, tag_buf = nil, ''
          end

          # Found a meta tag
          if line =~ meta_match
            tag_name, tag_buf = $1, $2 
          elsif indent >= last_indent && tag_name
            # Extra data added to the tag on the next line
            tag_buf << line
          else
            # Regular docstring text
            @docstring << line << "\n" 
          end

          last_indent = indent
        end

        # Remove trailing/leading whitespace / newlines
        @docstring.gsub!(/\A[\r\n\s]+|[\r\n\s]+\Z/, '')
      end      
    end
  end
end