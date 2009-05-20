module YARD
  module Handlers
    module Ruby
      class Base < Handlers::Base
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