module YARD
  module Templates
    module Helpers
      module HtmlSyntaxHighlightHelper
        def html_syntax_highlight_ruby(source)
          tokenlist = Parser::Ruby::RubyParser.parse(source, "(syntax_highlight)").tokens
          output = ""
          tokenlist.each do |s|
            output << "<span class='tstring'>" if [:tstring_beg, :regexp_beg].include?(s[0])
            case s.first
            when :nl, :ignored_nl, :sp
              output << h(s.last)
            when :ident
              output << "<span class='id #{h(s.last)}'>#{h(s.last)}</span>"
            else
              output << "<span class='#{s.first}'>#{h(s.last)}</span>"
            end
            output << "</span>" if [:tstring_end, :regexp_end].include?(s[0])
          end
          output
        rescue Parser::ParserSyntaxError
          h(source)
        end
      end
    end
  end
end