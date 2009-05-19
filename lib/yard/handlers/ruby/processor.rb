module YARD
  module Handlers
    module Ruby
      class Processor < Handlers::Processor
        protected
        
        def valid_handler?(handler, node)
          Base > handler &&
          handler.handlers.any? do |a_handler| 
            case a_handler 
            when Symbol
              a_handler == node.type
            when String
              if node.token?
                a_handler == node.first
              else
                a_handler == node.type.to_s
              end
            when Regexp
              if node.token?
                node.source =~ a_handler
              else
                node.type =~ a_handler
              end
            end
          end
        end
      end
    end
  end
end

