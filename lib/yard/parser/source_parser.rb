require 'stringio'
require 'continuation' unless RUBY18

module YARD
  module Parser
    class UndocumentableError < Exception; end
    class LoadOrderError < Exception; end
    
    # Responsible for parsing a source file into the namespace
    class SourceParser 
      class << self
        attr_accessor :parser_type
        
        def parser_type=(value)
          @parser_type = validated_parser_type(value)
        end
        
        def parse(paths = "lib/**/*.rb", level = log.level)
          log.debug("Parsing #{paths} with `#{parser_type}` parser")
          files = [paths].flatten.map {|p| p.include?("*") ? Dir[p] : p }

          log.enter_level(level) do
            parse_in_order(*files.uniq)
          end
        end
      
        def parse_string(content, ptype = parser_type)
          new(ptype).parse(StringIO.new(content))
        end
        
        def tokenize(content, ptype = parser_type)
          new(ptype).tokenize(content)
        end
        
        def validated_parser_type(type)
          RUBY18 && type == :ruby ? :ruby18 : type
        end

        private
        
        def parse_in_order(*files)
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
      
      attr_reader :file, :parser_type

      def initialize(parser_type = SourceParser.parser_type, load_order_errors = false)
        @load_order_errors = load_order_errors
        @file = '(stdin)'
        self.parser_type = parser_type
      end

      ##
      # Creates a new SourceParser that parses a file and returns
      # analysis information about it.
      #
      # @param [String, #read, Object] content the source file to parse
      def parse(content = __FILE__)
        case content
        when String
          @file = content
          content = IO.read(content)
          self.parser_type = parser_type_for_filename(file)
        else
          content = content.read if content.respond_to? :read
        end
        
        @parser = parse_statements(content)
        post_process
        @parser
      end
      
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

      def post_process
        post = Handlers::Processor.new(@file, @load_order_errors, @parser_type)
        post.process(@parser.enumerator)
      end

      def parser_type=(value)
        @parser_type = self.class.validated_parser_type(value)
      end
      
      def parser_type_for_filename(filename)
        case (File.extname(filename)[1..-1] || "").downcase
        when "c", "cpp", "cxx"
          :c
        else # when "rb", "rbx", "erb"
          parser_type == :ruby18 ? :ruby18 : :ruby
        end
      end
      
      def parse_statements(content)
        case parser_type
        when :c
          raise NotImplementedError, "no support for C/C++ files"
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
