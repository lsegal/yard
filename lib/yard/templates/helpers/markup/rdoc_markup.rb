# frozen_string_literal: true
require 'thread'

gem 'rdoc', '>= 6.0'
require 'rdoc'
require 'rdoc/markup'
require 'rdoc/markup/to_html'

module YARD
  module Templates
    module Helpers
      module Markup
        class RDocMarkup
          MARKUP = RDoc::Markup

          attr_accessor :from_path

          @@mutex = Mutex.new
          @@formatter = nil
          @@markup = nil

          # @param text [String]
          def initialize(text)
            @text = text

            @@mutex.synchronize do
              @@formatter ||= RDocMarkupToHtml.new
              @@markup ||= MARKUP.new
            end
          end

          # @return [String]
          def to_html
            html = nil
            @@mutex.synchronize do
              @@formatter.from_path = from_path
              html = @@markup.convert(@text, @@formatter)
            end
            html = fix_dash_dash(html)
            html = fix_typewriter(html)
            html
          end

          private

          # Fixes RDoc behaviour with ++ only supporting alphanumeric text.
          def fix_typewriter(text)
            code_tags = 0
            text.gsub(%r{<(/)?(pre|code|tt)|(\s|^|>)\+(?! )([^\n\+]{1,900})(?! )\+}) do |str|
              closed = $1
              tag = $2
              first_text = $3
              type_text = $4

              if tag
                code_tags += (closed ? -1 : 1)
                next str
              end
              next str unless code_tags == 0
              first_text + '<tt>' + type_text + '</tt>'
            end
          end

          # Don't allow -- to turn into &#8212; element (em dash)
          def fix_dash_dash(text)
            text.gsub(/&#8212;(?=\S)/, '--')
          end
        end

        # Specialized ToHtml formatter for YARD
        #
        # @todo Refactor into own SimpleMarkup subclass
        class RDocMarkupToHtml < RDoc::Markup::ToHtml
          attr_accessor :from_path

          def initialize
            options = RDoc::Options.new
            options.pipe = true
            super(options)

            # The hyperlink detection state
            @hyperlink = false
          end

          # Disable auto-link of URLs
          def handle_special_HYPERLINK(special) # rubocop:disable Style/MethodName
            @hyperlink ? special.text : super
          end

          def accept_paragraph(*args)
            par = args.last
            text = par.respond_to?(:txt) ? par.txt : par.text
            @hyperlink = text =~ /\{(https?:|mailto:|link:|www\.)/ ? true : false
            super
          end
        end
      end
    end
  end
end
