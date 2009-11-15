module YARD
  module Templates
    module Helpers
      module HtmlSyntaxHighlightHelper
        def html_syntax_highlight(source)
          return "" unless source
          return source if options[:no_highlight]
          tokenlist = Parser::Ruby::Legacy::TokenList.new(source)
          tokenlist.map do |s| 
            prettyclass = s.class.class_name.sub(/^Tk/, '').downcase
            prettysuper = s.class.superclass.class_name.sub(/^Tk/, '').downcase

            case s
            when Parser::Ruby::Legacy::RubyToken::TkWhitespace, Parser::Ruby::Legacy::RubyToken::TkUnknownChar
              h s.text
            when Parser::Ruby::Legacy::RubyToken::TkId
              prettyval = h(s.text)
              "<span class='#{prettyval} #{prettyclass} #{prettysuper}'>#{prettyval}</span>"
            else
              "<span class='#{prettyclass} #{prettysuper}'>#{h s.text}</span>"
            end
          end.join
        end
      end
    end
  end
end
