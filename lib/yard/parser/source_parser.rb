require 'stringio'
require 'continuation' unless RUBY18

module YARD
  module Parser
    class LoadOrderError < Exception; end
    
    # Responsible for parsing a source file into the namespace
    class SourceParser 
      class << self
        def parse(paths = "lib/**/*.rb", level = log.level)
          if paths.is_a?(Array)
            files = paths.map {|p| Dir[p] }.flatten
          else
            files = Dir[File.join(Dir.pwd, paths)]
          end

          log.enter_level(level) do
            parse_in_order(*files.uniq)
          end
        end
      
        def parse_string(content)
          new.parse(StringIO.new(content))
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
                new(true).parse(file)
              end
            rescue LoadOrderError => e
              # Out of order file. Push the context to the end and we'll call it
              files.push([file, e.message])
            end
          end
        end
      end
      
      attr_reader :file, :parser_type

      def initialize(load_order_errors = false)
        @load_order_errors = load_order_errors
      end

      ##
      # Creates a new SourceParser that parses a file and returns
      # analysis information about it.
      #
      # @param [String, #read, Object] content the source file to parse
      def parse(content = __FILE__, parser_type = :ruby)
        parser_type = :ruby18 if parser_type == :ruby && RUBY18
        @parser_type ||= parser_type
        case content
        when String
          @file = content
          content = IO.read(content)
          @parser_type = parser_type_for_filename(file)
        else
          content = content.read if content.respond_to? :read
        end

        @parser = parse_statements(content)
        post_process
        @parser
      end
      
      private

      def post_process
        post = Handlers::Processor.new(@file, @load_order_errors, @parser_type)
        post.process(@parser.enumerator)
      end
      
      def parser_type_for_filename(filename)
        case File.extname(filename)[1..-1].downcase
        when "c", "cpp", "cxx"
          :c
        else # when "rb", "rbx", "erb"
          RUBY18 ? :ruby18 : :ruby
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
