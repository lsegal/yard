module YARD
  class YieldHandler < CodeObjectHandler
    handles 'yield'
  
    def process
      tokens = statement.tokens.reject {|tk| [RubyToken::TkSPACE, RubyToken::TkLPAREN].include? tk.class }
      from = tokens.each_with_index do |token, index|
        break index if token.class == RubyToken::TkYIELD
      end
      if from.is_a? Fixnum
        params = []
        (from+1).step(tokens.size-1, 2) do |index|
          # FIXME: This won't work if the yield has a method call or complex constant name (A::B) 
          params << tokens[index].text
          break unless tokens[index+1].is_a? RubyToken::TkCOMMA
        end
      
        # Only add the tags if none were added at all
        if object.tags("yieldparam").empty? && object.tags("yield").empty?
          params.each do |param|
            # TODO: We can technically introspect any constant to find out parameter types,
            #       not just self.
            # If parameter is self, we have a chance to get some extra information
            if param == "self"
              param = "[#{object.parent.path}] _self the object that yields the value (self)"
            end
            object.tags << YARD::TagLibrary.yieldparam_tag(param)
          end
        end
      end
    end
  end
end