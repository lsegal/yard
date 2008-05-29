module YARD
  module Handlers
    class UndocumentableError < Exception; end
    
    class Base
      # For accessing convenience, eg. "MethodObject" 
      # instead of the full qualified namespace
      include YARD::CodeObjects
      
      # For tokens like TkDEF, TkCLASS, etc.
      include YARD::Parser::RubyToken
      
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
      
      def process
        raise NotImplementedError, "#{self} did not implement a #process method for handling."
      end
      
      attr_reader :parser, :statement

      def initialize(source_parser, stmt)
        @parser = source_parser
        @statement = stmt
      end
      
      def parse_block(opts = nil)
        opts = {
          :namespace => nil,
          :scope => :instance,
          :owner => nil
        }.update(opts || {})
        
        if opts[:namespace]
          ns, vis, sc = namespace, visibility, scope
          self.namespace = opts[:namespace]
          self.visibility = :public
          self.scope = opts[:scope]
        end

        self.owner = opts[:owner] ? opts[:owner] : namespace
        parser.parse(statement.block) if statement.block
        
        if opts[:namespace]
          self.namespace = ns
          self.owner = namespace
          self.visibility = vis
          self.scope = sc
        end
      end

      def owner; @parser.owner end
      def owner=(v) @parser.owner=(v) end
      def namespace; @parser.namespace end
      def namespace=(v); @parser.namespace=(v) end
      def visibility; @parser.visibility end
      def visibility=(v); @parser.visibility=(v) end
      def scope; @parser.scope end
      def scope=(v); @parser.scope=(v) end
    end
  end
end