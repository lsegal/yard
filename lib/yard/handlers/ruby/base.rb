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
      
      class Base < Handlers::Base
        class << self
          include Parser::Ruby
          
          def method_call(name)
            MethodCallWrapper.new(name.to_s)
          end
          
          def meta_type(meth)
            TestNodeWrapper.new(meth.to_s + "?")
          end
          
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