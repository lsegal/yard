require 'stringio'
require 'continuation' if RUBY19

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

      attr_reader :file
      attr_accessor :namespace, :visibility, :scope, :owner, :load_order_errors

      def initialize(load_order_errors = false)
        @file = "<STDIN>"
        @namespace = YARD::Registry.root
        @visibility = :public
        @scope = :instance
        @owner = @namespace
        @load_order_errors = load_order_errors
      end

      ##
      # Creates a new SourceParser that parses a file and returns
      # analysis information about it.
      #
      # @param [String, TokenList, StatementList, #read] content the source file to parse
      def parse(content = __FILE__)
        case content
        when String
          @file = content
          statements = StatementList.new(IO.read(content))
        when TokenList
          statements = StatementList.new(content)
        when StatementList
          statements = content
        else
          if content.respond_to? :read
            statements = StatementList.new(content.read)
          else
            raise ArgumentError, "Invalid argument for SourceParser::parse: #{content.inspect}:#{content.class}"
          end
        end

        top_level_parse(statements)
      end

      private
        def top_level_parse(statements)
            statements.each do |stmt|
              find_handlers(stmt).each do |handler| 
                begin
                  handler.new(self, stmt).process
                rescue LoadOrderError => loaderr
                  raise # Pass this up
                rescue Handlers::UndocumentableError => undocerr
                  log.warn "in #{handler.to_s}: Undocumentable #{undocerr.message}"
                  log.warn "\tin file '#{file}':#{stmt.tokens.first.line_no}:\n\n" + stmt.inspect + "\n"
                rescue => e
                  log.error "Unhandled exception in #{handler.to_s}:"
                  log.error "#{e.class.class_name}: #{e.message}"
                  log.error "  in `#{file}`:#{stmt.tokens.first.line_no}:\n\n#{stmt.inspect}\n"
                  log.error "Stack trace:" + e.backtrace[0..5].map {|x| "\n\t#{x}" }.join + "\n"
                end
              end
            end
        end

        def find_handlers(stmt)
          Handlers::Base.subclasses.find_all {|sub| sub.handles? stmt.tokens }
        end
    end
  end
end
