# frozen_string_literal: true
gem 'rdoc', '>= 6.0'
require 'rdoc'
require 'rdoc/markdown'

module YARD
  module Templates
    module Helpers
      module Markup
        class RDocMarkdown < RDocMarkup
          def initialize(text)
            super RDoc::Markdown.new.parse(text)
          end

          def fix_typewriter(html) html end
        end
      end
    end
  end
end
