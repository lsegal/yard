module YARD
  module Handlers
    module Ruby
      module Legacy
        # (see Ruby::MacroHandler)
        class MacroHandler < Base
          include CodeObjects
          include MacroHandlerMethods
          handles TkIDENTIFIER
          namespace_only
          process { handle_comments }
        end
      end
    end
  end
end
