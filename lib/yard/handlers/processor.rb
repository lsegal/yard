module YARD
  module Handlers
    class Processor
      attr_accessor :file, :namespace, :visibility
      attr_accessor :scope, :owner, :load_order_errors, :parser_type
      
      def initialize(file = nil, load_order_errors = false, parser_type = :ruby)
        @file = file || "(stdin)"
        @namespace = YARD::Registry.root
        @visibility = :public
        @scope = :instance
        @owner = @namespace
        @load_order_errors = load_order_errors
        @parser_type = parser_type
      end
      
      def process(statements)
        statements.each_with_index do |stmt, index|
          find_handlers(stmt).each do |handler| 
            begin
              handler.new(self, stmt).process
            rescue Parser::LoadOrderError => loaderr
              raise # Pass this up
            rescue UndocumentableError => undocerr
              log.warn "in #{handler.to_s}: Undocumentable #{undocerr.message}"
              log.warn "\tin file '#{file}':#{stmt.line}:\n\n" + stmt.inspect + "\n"
            rescue => e
              log.error "Unhandled exception in #{handler.to_s}:"
              log.error "#{e.class.class_name}: #{e.message}"
              log.error "  in `#{file}`:#{stmt.line}:\n\n#{stmt.show}\n"
              log.error "Stack trace:" + e.backtrace[0..5].map {|x| "\n\t#{x}" }.join + "\n"
            end
          end
        end
      end
      
      def find_handlers(statement)
        Base.subclasses.find_all do |handler|
          handler_base_class > handler &&
          handler.handles?(statement)
        end
      end
      
      private
      
      def handler_base_class
        case parser_type
        when :ruby
          Ruby::Base
        when :ruby18
          Ruby::Legacy::Base
        end
      end
    end
  end
end