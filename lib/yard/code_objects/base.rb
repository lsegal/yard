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
    
    NSEPQ = NSEP = '::'
    ISEPQ = ISEP = '#'
    CSEP = '.'
    CSEPQ = Regexp.quote CSEP
    CONSTANTMATCH = /[A-Z]\w*/
    NAMESPACEMATCH = /(?:(?:#{NSEPQ})?#{CONSTANTMATCH})+/
    METHODNAMEMATCH = /[a-zA-Z_]\w*[!?=]?|[-+~]\@|<<|>>|=~|===?|[<>]=?|\*\*|[-\/+%^&*~`|]|\[\]=?/
    METHODMATCH = /(?:(?:#{NAMESPACEMATCH}|self)\s*(?:#{CSEPQ}|#{NSEPQ})\s*)?#{METHODNAMEMATCH}/
    
    BUILTIN_EXCEPTIONS = ["SecurityError", "Exception", "NoMethodError", "FloatDomainError", 
      "IOError", "TypeError", "NotImplementedError", "SystemExit", "Interrupt", "SyntaxError", 
      "RangeError", "NoMemoryError", "ArgumentError", "ThreadError", "EOFError", "RuntimeError", 
      "ZeroDivisionError", "StandardError", "LoadError", "NameError", "LocalJumpError", "SystemCallError", 
      "SignalException", "ScriptError", "SystemStackError", "RegexpError", "IndexError"]
    # Note: MatchingData is a 1.8.x legacy class
    BUILTIN_CLASSES = ["TrueClass", "Array", "Dir", "Struct", "UnboundMethod", "Object", "Fixnum", "Float", 
      "ThreadGroup", "MatchingData", "MatchData", "Proc", "Binding", "Class", "Time", "Bignum", "NilClass", "Symbol", 
      "Numeric", "String", "Data", "MatchData", "Regexp", "Integer", "File", "IO", "Range", "FalseClass", 
      "Method", "Continuation", "Thread", "Hash", "Module"] + BUILTIN_EXCEPTIONS
    BUILTIN_MODULES = ["ObjectSpace", "Signal", "Marshal", "Kernel", "Process", "GC", "FileTest", "Enumerable", 
      "Comparable", "Errno", "Precision", "Math"]
    BUILTIN_ALL = BUILTIN_CLASSES + BUILTIN_MODULES
    
    BUILTIN_EXCEPTIONS_HASH = BUILTIN_EXCEPTIONS.inject({}) {|h,n| h.update(n => true) }
    
    class Base  
      attr_reader :name, :files
      attr_accessor :namespace, :source, :signature, :docstring, :dynamic
      
      def dynamic?; @dynamic end
      
      class << self
        def new(namespace, name, *args, &block)
          if name.to_s[0,2] == NSEP
            name = name.to_s[2..-1]
            namespace = Registry.root
          elsif name =~ /(?:#{NSEPQ}|#{ISEPQ}|#{CSEPQ})([^#{NSEPQ}#{ISEPQ}#{CSEPQ}]+)$/
            return new(Proxy.new(namespace, $`), $1, *args, &block)
          end
          
          keyname = namespace && namespace.respond_to?(:path) ? namespace.path : ''
          if self == RootObject
            keyname = :root
          elsif self == MethodObject
            keyname += (args.first && args.first.to_sym == :class ? CSEP : ISEP) + name.to_s
          elsif keyname.empty?
            keyname = name.to_s
          else
            keyname += NSEP + name.to_s
          end
          
          obj = Registry.objects[keyname]
          obj = nil if obj && obj.class != self
          
          if self != RootObject && obj
            yield(obj) if block_given?
            obj
          else
            Registry.objects[keyname] = super(namespace, name, *args, &block)
          end
        end
        
        def ===(other)
          self >= other.class ? true : false
        end
      end
          
      def initialize(namespace, name, *args)
        if namespace && namespace != :root && 
            !namespace.is_a?(NamespaceObject) && !namespace.is_a?(Proxy)
          raise ArgumentError, "Invalid namespace object: #{namespace}"
        end

        @files = []
        @current_file_has_comments = false
        @name = name.to_sym
        @tags = []
        @docstring = Docstring.new('', self)
        self.namespace = namespace
        yield(self) if block_given?
      end
      
      # Associates a file with a code object, optionally adding the line where it was defined.
      # By convention, '<STDIN>' should be used to associate code that comes form standard input.
      # 
      # @param [String] file the filename ('<STDIN>' for standard input)
      # @param [Fixnum, nil] the line number where the object lies in the file
      # @param [Boolean] whether or not the definition has comments associated. This
      #   will allow {#file} to return the definition where the comments were made instead
      #   of any empty definitions that might have been parsed before (module namespaces for instance).
      def add_file(file, line = nil, has_comments = false)
        raise(ArgumentError, "file cannot be nil or empty") if file.nil? || file == ''
        obj = [file.to_s, line]
        if has_comments && !@current_file_has_comments
          @current_file_has_comments = true
          @files.unshift(obj) 
        else
          @files << obj # back of the line
        end
      end
      
      # Returns the filename the object was first parsed at, taking
      # definitions with docstrings first.
      # 
      # @return [String] a filename
      def file
        @files.first ? @files.first[0] : nil
      end

      # Returns the line the object was first parsed at (or nil)
      # 
      # @return [Fixnum] the line where the object was first defined.
      # @return [nil] if there is no line associated with the object
      def line
        @files.first ? @files.first[1] : nil
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
          self[meth.to_s[0..-2]] = args.first
        elsif instance_variable_get("@#{meth}")
          self[meth]
        else
          super
        end
      end

      ##
      # Attaches source code to a code object with an optional file location
      #
      # @param [#source, String] statement 
      #   the +Parser::Statement+ holding the source code or the raw source 
      #   as a +String+ for the definition of the code object only (not the block)
      def source=(statement)
        if statement.respond_to?(:source)
          self.line = statement.line
          self.signature = statement.first_line
          @source = format_source(statement.source.strip)
        else
          @source = format_source(statement.to_s)
        end
      end

      ##
      # Attaches a docstring to a code oject by parsing the comments attached to the statement
      # and filling the {#tags} and {#docstring} methods with the parsed information.
      #
      # @param [String, Array<String>, Docstring] comments 
      #   the comments attached to the code object to be parsed 
      #   into a docstring and meta tags.
      def docstring=(comments)
        @docstring = Docstring === comments ? comments : Docstring.new(comments, self)
      end
      
      ##
      # Default type is the lowercase class name without the "Object" suffix
      # 
      # Override this method to provide a custom object type 
      # 
      # @return [Symbol] the type of code object this represents
      def type
        self.class.name.split(/#{NSEPQ}/).last.gsub(/Object$/, '').downcase.to_sym
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

      def tag(name); @docstring.tag(name) end
      def tags(name = nil); @docstring.tags(name) end
      def has_tag?(name); @docstring.has_tag?(name) end

      protected
    
      def sep; NSEP end

      # Formats source code by removing leading indentation
      def format_source(source)
        source.chomp!
        indent = source.split(/\r?\n/).last[/^([ \t]*)/, 1].length
        source.gsub(/^[ \t]{#{indent}}/, '')
      end
    end
  end
end
