module YARD
  module Handlers
    class Processor
      attr_accessor :file, :namespace, :visibility
      attr_accessor :scope, :owner, :load_order_errors, :parser_type
      
      def initialize(file = nil, load_order_errors = false, parser_type = Parser::SourceParser.parser_type)
        @file = file || "(stdin)"
        @namespace = YARD::Registry.root
        @visibility = :public
        @scope = :instance
        @owner = @namespace
        @load_order_errors = load_order_errors
        @parser_type = parser_type
        @handlers_loaded = {}
        load_handlers
      end
      
      def process(statements)
        statements.each_with_index do |stmt, index|
          find_handlers(stmt).each do |handler| 
            begin
              handler.new(self, stmt).process
            rescue Parser::LoadOrderError => loaderr
              raise # Pass this up
            rescue NamespaceMissingError => missingerr
              log.warn "The #{missingerr.object.type} #{missingerr.object.path} has not yet been recognized." 
              log.warn "If this class/method is part of your source tree, this will affect your documentation results." 
              log.warn "You can correct this issue by loading the source file for this object before `#{file}'"
              log.warn 
            rescue Parser::UndocumentableError => undocerr
              log.warn "in #{handler.to_s}: Undocumentable #{undocerr.message}"
              log.warn "\tin file '#{file}':#{stmt.line}:\n\n" + stmt.show + "\n"
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
          (handler.namespace_only? ? owner.is_a?(CodeObjects::NamespaceObject) : true) &&
          handler.handles?(statement)
        end
      end
      
      private
      
      def handler_base_class
        handler_base_namespace.const_get(:Base)
      end

      def handler_base_namespace
        case parser_type
        when :ruby;   Ruby
        when :ruby18; Ruby::Legacy
        end
      end
      
      def load_handlers
        return if @handlers_loaded[parser_type]
        handler_base_namespace.constants.each {|c| handler_base_namespace.const_get(c) }
        @handlers_loaded[parser_type] = true
      end
    end
  end
end