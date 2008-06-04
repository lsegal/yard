module YARD
  module Generators
    class FullDocGenerator < Base
      before_generate :is_namespace?
      before_list :generate_assets
      before_list :generate_index
      before_list :generate_readme
      
      def sections_for(object) 
        case object
        when CodeObjects::ClassObject
          [:header, [G(ClassGenerator)]]
        when CodeObjects::ModuleObject
          [:header, [G(ModuleGenerator)]]
        end
      end
      
      protected
      
      def css_file; 'style.css' end
      def css_syntax_file; 'syntax_highlight.css' end
      def js_file; 'jquery.js' end
      def js_app_file; 'app.js' end
      
      def readme_file
        @readme_file ||= [options[:readme]].flatten.compact.find do |readme|
          File.exists?(readme)
        end
      end
      
      def generate_assets
        if format == :html && serializer
          [css_file, css_syntax_file, js_file, js_app_file].each do |filename|
            template_file = find_template template_path(filename)
            serializer.serialize(filename, File.read(template_file))
          end
        end
        true
      end
      
      def generate_index
        if format == :html && serializer
          serializer.serialize 'index.html', render(:index)
          serializer.serialize 'all-namespaces.html', render(:all_namespaces)
          serializer.serialize 'all-methods.html', render(:all_methods)
        end
        true
      end
      
      def generate_readme
        if format == :html && serializer && readme_file
          @contents = File.read(readme_file)
          serializer.serialize 'readme.html', render(:readme)
        end
        true
      end
    end
  end
end