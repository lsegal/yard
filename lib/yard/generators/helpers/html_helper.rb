require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module YARD::Generators::Helpers
  module HtmlHelper
    SMP = SM::SimpleMarkup.new
    SMH = SM::ToHtml.new
    
    def htmlify(text)
    end

    def linkify(object, title = nil, anchor = nil) 
      return title || object.path unless serializer
      
      from = serializer.serialized_path(current_object)
      to = serializer.serialized_path(object)
      
      
    end
    
    private
    
    def relative_path(from, to)
      from.squeeze!("/"); to.squeeze!("/")
      from, to = from.split('/'), to.split('/')
      from.length.times do 
        break if from[0] != to[0] 
        from.shift; to.shift
      end
      fname = from.pop
      File.join *(from.map { '..' } + to)
    end
  end
end
    
    