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
      
      attr_reader :parser, :statement

      def initialize(source_parser, stmt)
        @parser = source_parser
        @statement = stmt
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