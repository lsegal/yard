require File.dirname(__FILE__) + '/../../parser/ruby/ast_node'

module YARD
  module Handlers
    module Ruby
      class MethodCallWrapper
        def initialize(name) 
          @name = name.to_s
        end
        
        def matches?(node)
          case node.type
          when :var_ref
            if !node.parent || node.parent.type == :list
              return true if node[0].type == :ident && node[0][0] == @name
            end
          when :fcall, :command
            return true if node[0][0] == @name
          when :call, :command_call
            return true if node[2][0] == @name
          end
          false
        end
      end
      
      class Base < Handlers::Base
        class << self
          include Parser::Ruby
          
          def method_call(name)
            MethodCallWrapper.new(name)
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
              when MethodCallWrapper
                a_handler.matches?(node)
              end
            end
          end
        end

        include Parser::Ruby
        
        def parse_block(inner_node, opts = nil)
          opts = {
            namespace: nil,
            scope: :instance,
            owner: nil
          }.update(opts || {})

          if opts[:namespace]
            ns, vis, sc = namespace, visibility, scope
            self.namespace = opts[:namespace]
            self.visibility = :public
            self.scope = opts[:scope]
          end

          self.owner = opts[:owner] ? opts[:owner] : namespace
          nodes = inner_node.type == :list ? inner_node.children : [inner_node]
          parser.process(nodes)

          if opts[:namespace]
            self.namespace = ns
            self.owner = namespace
            self.visibility = vis
            self.scope = sc
          end
        end
      end
    end
  end
end