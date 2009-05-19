module YARD
  module Handlers
    module Ruby::Legacy
      class Processor < Handlers::Processor
        protected
        
        def valid_handler?(handler, stmt)
          Base > handler &&
          handler.handlers.any? do |a_handler|
            case a_handler
            when String
              stmt.tokens.first.text == a_handler
            when Regexp
              stmt.tokens.to_s =~ a_handler
            else
              a_handler == stmt.tokens.first.class 
            end
          end
        end
      end
    end
  end
end