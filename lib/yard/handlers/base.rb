module YARD
  module Handlers
    class Base
      # For accessing convenience, eg. "MethodObject" 
      # instead of the full qualified namespace
      include YARD::CodeObjects
      
      class << self
        def clear_subclasses
          @@subclasses = []
        end
        
        def subclasses
          @@subclasses || []
        end

        def inherited(subclass)
          @@subclasses ||= []
          @@subclasses << subclass
        end

        def handles(token)
          @handler = token
        end

        def handles?(tokens)
          case @handler
          when String
            tokens.first.text == @handler
          when Regexp
            tokens.to_s =~ @handler ? true : false
          else
            @handler == tokens.first.class 
          end
        end
      end
      
      def process; end
      
      attr_reader :parser, :statement

      def initialize(source_parser, stmt)
        @parser = source_parser
        @statement = stmt
      end
      
      def parse_block(new_namespace = nil, new_scope = :instance)
        if new_namespace
          ns, vis, scope = namespace, visibility, scope
          self.namespace = new_namespace
          self.visibility = :public
          self.scope = new_scope
        end

        parser.parse(statement.block) if statement.block
        
        if new_namespace
          self.namespace = ns
          self.visibility = vis
          self.scope = scope
        end
      end

      def namespace; @parser.namespace end
      def namespace=(v); @parser.namespace=(v) end
      def visibility; @parser.visibility end
      def visibility=(v); @parser.visibility=(v) end
      def scope; @parser.scope end
      def scope=(v); @parser.scope=(v) end
    end
  end
end