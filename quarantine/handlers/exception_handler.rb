class YARD::ExceptionHandler < YARD::CodeObjectHandler
  handles 'raise'
  
  def process
    tokens = statement.tokens.reject {|tk| [RubyToken::TkSPACE, RubyToken::TkLPAREN].include? tk }
    from = tokens.each_with_index do |token, index|
      break index if token.class == RubyToken::TkIDENTIFIER && token.text == 'raise'
    end
    if from.is_a? Fixnum
      exception_class = tokens[(from+1)..-1].to_s[/^\W+(\w+)/, 1]
      # RuntimeError for Strings or no parameter
      exception_class = "RuntimeError" if exception_class =~ /^["']/ || exception_class.nil?
      
      # Only add the tag if it hasn't already been added (by exception class).
      unless object.tags("raise").any? {|tag| tag.name == exception_class }
        object.tags << YARD::TagLibrary.raise_tag(exception_class)
      end
    end
  end
end