module YARD
  module Handlers
    module Ruby
      # Handles a macro (dsl-style method)
      class MacroHandler < Base
        include CodeObjects
        include MacroHandlerMethods
        handles method_call
        namespace_only
        process { handle_comments }
      end
    end
  end
end
