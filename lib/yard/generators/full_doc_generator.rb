module YARD
  module Generators
    class FullDocGenerator < Base
      before_generate :is_namespace?
      before_generate :generate_stylesheet
      
      def sections_for(object) 
        case object
        when CodeObjects::ClassObject
          [:header, [G(ClassGenerator)]]
        when CodeObjects::ModuleObject
          [:header, [G(ModuleGenerator)]]
        end
      end
      
      protected
      
      CSS_FILE = 'style.css'
      
      def generate_stylesheet
        if format == :html && serializer
          cssfile = find_template template_path(CSS_FILE)
          serializer.serialize(CSS_FILE, File.read(cssfile))
        end
      end
    end
  end
end