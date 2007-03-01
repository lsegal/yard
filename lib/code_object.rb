require File.dirname(__FILE__) + '/tag_library'
require File.dirname(__FILE__) + '/formatter'

module YARD #:nodoc:  
  ## 
  # The documentation parser is responsible for parsing the docstring into
  # text and saving the meta tags attached to it
  # 
  # @author Loren Segal
  class CodeObject
    attr_reader :source, :full_source, :file, :line, :docstring, :attributes
    
    attr_reader :name, :type
    attr_accessor :visibility, :scope 
    attr_accessor :parent, :children
    
    ##
    # Creates a new code object with necessary information such as the object's name (not full path),
    # it's type (:class, :module, :method, etc.), visibility (:public, :private, :protected) and scope
    # (:instance or :class level). Optionally you can specify a parent object and comments too, but these
    # can also be assigned later through the {#parent=} and {#attach_docstring} methods.
    #
    # @param [String] name        the name of the object, not including its namespace ('initialize' for this method)
    # @param [Symbol] type        the type of object this is, including (but not limited to): 
    #                             :module, :class, :method, :constant
    # @param [Symbol] visibility  :public, :protected or :private depending on the visibility of the object
    # @param [Symbol] scope       :instance or :class depending on if the object is instance level or class level.
    #                             Instance level objects use the '#' character to separate from their parent instead of '::'
    # @param [CodeObject] parent  The parent of this object. Without a parent this object will not be registered
    #                             in the {Namespace}
    # @param [String] comments    Comments to be parsed as a docstring for the object. 
    # @return [CodeObject] the created code object
    # @yieldparam [CodeObject] _self the object is yielded during initialization to perform any initialization operations
    #                                on it more conveniently.
    # @see #attach_docstring
    # @see #parent=
    def initialize(name, type, visibility = :public, scope = :instance, parent = nil, comments = nil)
      @name, @type, @visibility, @scope = name, type, visibility.to_sym, scope.to_sym
      @tags, @attributes, @children = [], {}, []
      self.parent = parent
      attach_docstring(comments)
      yield(self) if block_given?
    end
    
    def to_s
      "#{visibility} #{type} #{path}"
    end
    
    ##
    # Attaches source code to a code object with an optional file location
    #
    # @param [Statement, String] statement the +Statement+ holding the source code
    #                                      or the raw source as a +String+ for the 
    #                                      definition of the code object only (not the block)
    # @param [String] file the filename the source resides in
    def attach_source(statement, file = nil)
      if statement.is_a? String
        @source = statement
      else
        @source = statement.tokens.to_s
        @line = statement.tokens.first.line_no
        attach_full_source statement.tokens.to_s + (statement.block.to_s rescue "")
      end
      @file = file
    end
    
    ##
    # Manually attaches full source code for an object given the source
    # as a +String+
    # 
    # @param [String] source the source code for the object
    def attach_full_source(source)
      @full_source = source
    end
    
    ##
    # Attaches a docstring to a code oject by parsing the comments attached to the statement
    # and filling the {#tags} and {#docstring} methods with the parsed information.
    #
    # @param [String, Array<String>] comments the comments attached to the code object to be
    #                                         parsed into a docstring and meta tags.
    def attach_docstring(comments)
      parse_comments(comments) if comments
    end
    
    def [](key)
      @attributes[key.to_sym]
    end
    
    def []=(key, value)
      @attributes[key.to_sym] = value
    end
    
    ## 
    # Sets the parent object and registers the object path with
    # the {Namespace}. If the object was already registered
    # to an old path, it will be removed from the namespace.
    #
    # @param [CodeObject] value the new parent object
    # @see Namespace
    def parent=(value)
      # Delete old object path if there was one
      Namespace.instance.namespace.delete(path) if parent
      
      @parent = value
      
      # Register new path with namespace
      Namespace.add_object(self) if value
    end
    
    ##
    # See if the method call exists in the attributes hash, and return
    # it. Otherwise send the missing method call up the stack.
    #
    # @param meth the method name called. This method is checked in the 
    #             attributes hash
    # @param args the arguments to the call
    # @param block an optional block for the call
    def method_missing(meth, *args, &block)
      return self[meth] if self[meth]
      super
    end
    
    ##
    # Returns the unique path for this code object. The resulting path will be
    # a Ruby style path name of the namespace the object resides in plus the
    # object name delimited by a "::" or "#" depending on if the object is an
    # instance level object or a class level object.
    #
    # Example:
    #   
    #
    #
    def path
      [(parent.path if parent && parent.type != :root), name].join(scope == :instance ? "#" : "::").gsub(/^::/, '')
    end
    
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
    
    ##
    # Returns a code object formatted as a given type, defaults to html.
    # 
    # @param [Symbol] format the output format to generate
    # @return [String] the code object formatted by the specified +format+
    def format(type = :html)
      Formatter.new.format(self, type)
    end
    
    private
      ##
      # Parses out comments split by newlines into a new code object
      #
      # @param [Array<String>, String] comments the newline delimited 
      #                                         array of comments. If the comments
      #                                         are passed as a String, they will
      #                                         be split by newlines. 
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
  
  class CodeObjectWithMethods < CodeObject
    def initialize(name, type, parent = nil, comments = nil)
      super(name, type, :public, :class, parent, comments) do |obj|
        obj[:instance_methods] = {}
        obj[:class_methods] = {}
        obj[:constants] = {}
        obj[:class_variables] = {}
        obj[:mixins] = []
        yield(obj) if block_given?
      end
    end
    
    def inherited_class_methods
      inherited_methods(:class)
    end
    
    def inherited_instance_methods
      inherited_methods(:instance)
    end
    
    def inherited_methods(scopes = [:class, :instance])
      [scopes].flatten.each do |scope|
        full_mixins.inject({}) {|hash, mixin| hash.update(mixin.send(scope + "_methods")) }
      end
    end
    
    def full_mixins 
      mixins.collect {|mixin| Namespace.find_from_path(self, mixin).path rescue mixin }
    end
  end

  class ModuleObject < CodeObjectWithMethods
    def initialize(name, *args)
      super(name, :module, *args) do |obj|
        yield(obj) if block_given?
      end
    end
  end

  class ClassObject < CodeObjectWithMethods
    BASE_OBJECT = "Object"
    
    def initialize(name, superclass = BASE_OBJECT, *args)
      super(name, :class, *args) do |obj|
        obj[:attributes] = {}
        obj[:superclass] = superclass
        yield(obj) if block_given?
      end
    end
    
    def inherited_methods(scopes = [:class, :instance])
      inherited_methods = super
      superobject = Namespace.find_from_path(path, superclass)
      if superobject && superobject.path != path # avoid infinite loop
        [scopes].flatten.each do |scope|
          inherited_methods.update(superobject.send(scope + "_methods"))
          inherited_methods.update(superobject.send("inherited_#{scope}_methods"))
        end
      end
      inherited_methods
    end
    
    def superclasses
      superobject = Namespace.find_from_path(path, superclass)
      return [superclass] if superobject.nil?
      [superobject.path] + superobject.superclasses
    end
    
    def inheritance_tree
      full_mixins.reverse + superclasses
    end
  end
  
  class MethodObject < CodeObject
    # @param [String] name the name of the method
    # @param visibility the object visibility (:public, :private, :protected)
    # @param [String] scope the object scope (:instance, :class)
    # @param [CodeObjectWithMethods] parent the object that holds this method
    def initialize(name, visibility, scope, parent, comments = nil)
      super(name, :method, visibility, scope, parent, comments) do |obj|
        parent["#{scope}_methods".to_sym].update(name.to_s => obj)
        yield(obj) if block_given?
      end
    end
  end
  
  class ConstantObject < CodeObject
    def initialize(name, parent = nil, statement = nil)
      super(name, :constant, :public, :class, parent) do |obj| 
        if statement
          obj.attach_docstring(statement.comments)
          obj.attach_source(statement)
          parent[:constants].update(name.to_s => obj)
          yield(obj) if block_given?
        end
      end
    end
  end
  
  class ClassVariableObject < CodeObject
    def initialize(statement, parent)
      name, value = *statement.tokens.to_s.gsub(/\r?\n/, '').split(/\s*=\s*/, 2)
      super(name, :class_variable, :public, :class, parent) do |obj| 
        obj.parent[:class_variables].update(name => obj)
        obj.attach_docstring(statement.comments)
        obj.attach_source("#{name} = #{value}")
      end
    end
  end
end
