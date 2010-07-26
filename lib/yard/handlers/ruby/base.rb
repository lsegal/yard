module YARD
  module Handlers
    module Ruby
      class HandlesExtension
        def initialize(name) @name = name end
        def matches?(node) raise NotImplementedError end
        protected
        attr_reader :name
      end
      
      class MethodCallWrapper < HandlesExtension
        def matches?(node)
          case node.type
          when :var_ref
            if !node.parent || node.parent.type == :list
              return true if node[0].type == :ident && node[0][0] == name
            end
          when :fcall, :command
            return true if node[0][0] == name
          when :call, :command_call
            return true if node[2][0] == name
          end
          false
        end
      end
      
      class TestNodeWrapper < HandlesExtension
        def matches?(node) !node.send(name).is_a?(FalseClass) end
      end
      
      # This is the base handler class for the new-style (1.9) Ruby parser.
      # All handlers that subclass this base class will be used when the 
      # new-style parser is used. For implementing legacy handlers, see
      # {Legacy::Base}.
      # 
      # @abstract See {Handlers::Base} for subclassing information.
      # @see Handlers::Base
      # @see Legacy::Base
      class Base < Handlers::Base
        class << self
          include Parser::Ruby
          
          # Matcher for handling any type of method call. Method calls can
          # be expressed by many {AstNode} types depending on the syntax
          # with which it is called, so YARD allows you to use this matcher
          # to simplify matching a method call.
          # 
          # @example Match the "describe" method call
          #   handles method_call(:describe)
          #   
          #   # The following will be matched:
          #   # describe(...)
          #   # object.describe(...)
          #   # describe "argument" do ... end
          # 
          # @param [#to_s] name matches the method call of this name
          # @return [void]
          def method_call(name)
            MethodCallWrapper.new(name.to_s)
          end
          
          # Matcher for handling a node with a specific meta-type. An {AstNode}
          # has a {AstNode#type} to define its type but can also be associated
          # with a set of types. For instance, +:if+ and +:unless+ are both
          # of the meta-type +:condition+.
          # 
          # A meta-type is any method on the {AstNode} class ending in "?", 
          # though you should not include the "?" suffix in your declaration.
          # Some examples are: "condition", "call", "literal", "kw", "token",
          # "ref".
          # 
          # @example Handling any conditional statement (if, unless)
          #   handles meta_type(:condition)
          # @param [Symbol] type the meta-type to match. A meta-type can be
          #   any method name + "?" that {AstNode} responds to.
          # @return [void]
          def meta_type(type)
            TestNodeWrapper.new(type.to_s + "?")
          end
          
          # @return [Boolean] whether or not an {AstNode} object should be
          #   handled by this handler
          def handles?(node)
            handlers.any? do |a_handler| 
              case a_handler 
              when Symbol
                a_handler == node.type
              when String
                node.source == a_handler
              when Regexp
                node.source =~ a_handler
              when Parser::Ruby::AstNode
                a_handler == node
              when HandlesExtension
                a_handler.matches?(node)
              end
            end
          end
        end

        include Parser::Ruby
        
        def parse_block(inner_node, opts = {})
          push_state(opts) do
            nodes = inner_node.type == :list ? inner_node.children : [inner_node]
            parser.process(nodes)
          end
        end
      end
    end
  end
end