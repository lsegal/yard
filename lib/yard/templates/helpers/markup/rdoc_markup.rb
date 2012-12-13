module YARD
  module Templates
    module Helpers
      module Markup
        begin require 'rdoc'; rescue LoadError; end
        begin
          require 'rdoc/markup'
          require 'rdoc/markup/to_html'
          class RDocMarkup; MARKUP = RDoc::Markup end
          class RDocMarkupToHtml < RDoc::Markup::ToHtml; end
        rescue LoadError
          begin
            require 'rdoc/markup/simple_markup'
            require 'rdoc/markup/simple_markup/to_html'
            class RDocMarkup; MARKUP = SM::SimpleMarkup end
            class RDocMarkupToHtml < SM::ToHtml; end
          rescue LoadError
            raise NameError, "could not load RDocMarkup (rdoc is not installed)"
          end
        end

        class RDocMarkup
          attr_accessor :from_path

          def initialize(text)
            @text = text
            @markup = MARKUP.new
          end

          def to_html
            formatter = RDocMarkupToHtml.new
            formatter.from_path = from_path
            html = @markup.convert(@text, formatter)
            html = fix_dash_dash(html)
            html = fix_typewriter(html)
            html
          end

          private

          # Fixes RDoc behaviour with ++ only supporting alphanumeric text.
          #
          # @todo Refactor into own SimpleMarkup subclass
          def fix_typewriter(text)
            code_tags = 0
            text.gsub(/<(\/)?(pre|code|tt)|(\s|^|>)\+(?! )([^\n\+]{1,900})(?! )\+/) do |str|
              closed, tag, first_text, type_text = $1, $2, $3, $4

              if tag
                code_tags += (closed ? -1 : 1)
                next str
              end
              next str unless code_tags == 0
              first_text + '<tt>' + CGI.escapeHTML(type_text) + '</tt>'
            end
          end

          # Don't allow -- to turn into &#8212; element. The chances of this being
          # some --option is far more likely than the typographical meaning.
          #
          # @todo Refactor into own SimpleMarkup subclass
          def fix_dash_dash(text)
            text.gsub(/&#8212;(?=\S)/, '--')
          end
        end

        class RDocMarkupToHtml
          attr_accessor :from_path

          # Disable auto-link of URLs
          def handle_special_HYPERLINK(special)
            @hyperlink ? special.text : super
          end

          def accept_paragraph(*args)
            par = args.last
            text = par.respond_to?(:txt) ? par.txt : par.text
            @hyperlink = !!(text =~ /\{(https?:|mailto:|link:|www\.)/)
            super
          end
        end
      end
    end
  end
end
