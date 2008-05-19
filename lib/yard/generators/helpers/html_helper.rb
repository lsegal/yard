require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module YARD::Generators::Helpers
  module HtmlHelper
    SMP = SM::SimpleMarkup.new
    SMH = SM::ToHtml.new

    def linkify(object, title = nil) 
      object.path 
    end
  end
end
    
    