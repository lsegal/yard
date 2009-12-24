require 'stringio'
require 'continuation' unless RUBY18

module YARD
  module Parser
    # Raised when an object is recognized but cannot be documented. This
    # generally occurs when the Ruby syntax used to declare an object is
    # too dynamic in nature. 
    class UndocumentableError < Exception; end
    
    # Raised when the parser sees a Ruby syntax error
    class ParserSyntaxError < UndocumentableError; end
    
    # A LoadOrderError occurs when a handler needs to modify a 
    # {CodeObjects::NamespaceObject} (usually by adding a child to it)
    # that has not yet been resolved. 
    # 
    # @see Handers::Base#ensure_loaded!
    class LoadOrderError < Exception; end
    
    # Responsible for parsing a source file into the namespace. Parsing
    # also invokes handlers to process the parsed statements and generate
    # any code objects that may be recognized.
    # 
    # @see Handlers::Base
    # @see CodeObjects::Base
    class SourceParser 
      class << self
        # The default parser type to use for blocks of code. Change this
        # attribute to apply a new parser type for all newly parsed
        # blocks of code.
        # 
        # @return [Symbol] the parser type
        attr_accessor :parser_type
        undef parser_type=
        
        # Sets the parser and makes sure it's a valid type
        # 
        # @param [Symbol] value the new parser type
        # @return [void] 
        def parser_type=(value)
          @parser_type = validated_parser_type(value)
        end
        
        # Parses a path or set of paths
        # 
        # @param [String, Array<String>] paths a path, glob, or list of paths to
        #   parse
        # @param [Array<String, Regexp>] excluded a list of excluded path matchers
        # @param [Fixnum] level the logger level to use during parsing. See
        #   {YARD::Logger}
        # @return the parser object that was used to parse the source. 
        def parse(paths = ["lib/**/*.rb", "ext/**/*.c"], excluded = [], level = log.level)
          log.debug("Parsing #{paths} with `#{parser_type}` parser")
          excluded = excluded.map do |path|
            case path
            when Regexp; path
            else Regexp.new(path.to_s, Regexp::IGNORECASE)
            end
          end
          files = [paths].flatten.
            map {|p| File.directory?(p) ? "#{p}/**/*.{rb,c}" : p }.
            map {|p| p.include?("*") ? Dir[p] : p }.flatten.
            reject {|p| !File.file?(p) || excluded.any? {|re| p =~ re } }

          log.enter_level(level) do
            parse_in_order(*files.uniq)
          end
        end
      
        # Parses a string +content+
        # 
        # @param [String] content the block of code to parse
        # @param [Symbol] ptype the parser type to use. See {parser_type}.
        # @return the parser object that was used to parse +content+
        def parse_string(content, ptype = parser_type)
          new(ptype).parse(StringIO.new(content))
        end
        
        # Tokenizes but does not parse the block of code
        # 
        # @param [String] content the block of code to tokenize
        # @param [Symbol] ptype the parser type to use. See {parser_type}.
        # @return [Array] a list of tokens
        def tokenize(content, ptype = parser_type)
          new(ptype).tokenize(content)
        end
        
        # Returns the validated parser type. Basically, enforces that :ruby
        # type is never set from Ruby 1.8
        # 
        # @param [Symbol] type the parser type to set
        # @return [Symbol] the validated parser type
        def validated_parser_type(type)
          RUBY18 && type == :ruby ? :ruby18 : type
        end

        private
        
        # Parses a list of files in a queue. If a {LoadOrderError} is caught,
        # the file is moved to the back of the queue with a Continuation object
        # that can continue processing the file.
        # 
        # @param [Array<String>] files a list of files to queue for parsing
        # @return [void]
        def parse_in_order(*files)
          files = files.sort_by {|x| x.length if x }
          while file = files.shift
            begin
              if file.is_a?(Array) && file.last.is_a?(Continuation)
                log.debug("Re-processing #{file.first}")
                file.last.call
              elsif file.is_a?(String)
                log.debug("Processing #{file}...")
                new(parser_type, true).parse(file)
              end
            rescue LoadOrderError => e
              # Out of order file. Push the context to the end and we'll call it
              files.push([file, e.message])
            end
          end
        end
      end

      self.parser_type = :ruby
      
      # The filename being parsed by the parser.
      attr_reader :file
      
      # The parser type associated with the parser instance. This should
      # be set by the {#initialize constructor}.
      attr_reader :parser_type

      # Creates a new parser object for code parsing with a specific parser type.
      # 
      # @param [Symbol] parser_type the parser type to use
      # @param [Boolean] load_order_errors whether or not to raise the {LoadOrderError}
      def initialize(parser_type = SourceParser.parser_type, load_order_errors = false)
        @load_order_errors = load_order_errors
        @file = '(stdin)'
        self.parser_type = parser_type
      end

      # The main parser method. This should not be called directly. Instead,
      # use the class methods {parse} and {parse_string}.
      #
      # @param [String, #read, Object] content the source file to parse
      # @return [Object, nil] the parser object used to parse the source
      def parse(content = __FILE__)
        case content
        when String
          @file = content
          content = convert_encoding(File.read_binary(content))
          checksum = Registry.checksum_for(content)
          return if Registry.checksums[file] == checksum

          if Registry.checksums.has_key?(file)
            log.info "File '#{file}' was modified, re-processing..."
          end
          Registry.checksums[@file] = checksum
          self.parser_type = parser_type_for_filename(file)
        else
          content = content.read if content.respond_to? :read
        end
        
        @parser = parse_statements(content)
        post_process
        @parser
      rescue ArgumentError, NotImplementedError => e
        log.warn("Cannot parse `#{file}': #{e.message}")
      rescue ParserSyntaxError => e
        log.warn(e.message.capitalize)
      end
      
      # Tokenizes but does not parse the block of code using the current {#parser_type}
      # 
      # @param [String] content the block of code to tokenize
      # @return [Array] a list of tokens
      def tokenize(content)
        case parser_type
        when :c
          raise NotImplementedError, "no support for C/C++ files"
        when :ruby18
          Ruby::Legacy::TokenList.new(content)
        when :ruby
          Ruby::RubyParser.parse(content).tokens
        else
          raise ArgumentError, "invalid parser type or unrecognized file"
        end
      end
      
      private
      
      # Searches for encoding line and forces encoding
      def convert_encoding(content)
        return content if RUBY18
        if content =~ /\A\s*#.*coding:\s*(\S+)\s*$/
          content.force_encoding($1)
        else
          content
        end
      end

      # Runs a {Handlers::Processor} object to post process the parsed statements.
      # @return [void] 
      def post_process
        return unless @parser.respond_to? :enumerator
        post = Handlers::Processor.new(@file, @load_order_errors, @parser_type)
        post.process(@parser.enumerator)
      end

      def parser_type=(value)
        @parser_type = self.class.validated_parser_type(value)
      end
      
      # Guesses the parser type to use depending on the file extension.
      # 
      # @param [String] filename the filename to use to guess the parser type
      # @return [Symbol] a parser type that matches the filename
      def parser_type_for_filename(filename)
        case (File.extname(filename)[1..-1] || "").downcase
        when "c", "cpp", "cxx"
          :c
        else # when "rb", "rbx", "erb"
          parser_type == :ruby18 ? :ruby18 : :ruby
        end
      end
      
      # Selects a parser to use to parse +content+.
      # 
      # @param [String] content the block of code to parse
      # @return the resulting parser object
      def parse_statements(content)
        case parser_type
        when :c
          CParser.new(content, file).parse
        when :ruby18
          Ruby::Legacy::StatementList.new(content)
        when :ruby
          Ruby::RubyParser.parse(content, file)
        else
          raise ArgumentError, "invalid parser type or unrecognized file"
        end
      end
    end
  end
end
