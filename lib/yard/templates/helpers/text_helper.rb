module YARD
  module Templates
    module Helpers
      module TextHelper
        def wrap(text, col = 72)
          text.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/, "\\1\\3\n") 
        end
                
        def indent(text, len = 4)
          text.gsub(/^/, ' ' * len)
        end
      end
    end
  end
end