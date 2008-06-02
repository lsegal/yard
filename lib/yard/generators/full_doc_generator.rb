module YARD
  module Generators
    class FullDocGenerator < Base
      before_generate :is_namespace?
      before_list :generate_stylesheet
      before_list :generate_index
      before_list :generate_navigation
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
      
      def readme_file
        @readme_file ||= [options[:readme]].flatten.compact.find do |readme|
          File.exists?(readme)
        end
      end
      
      def generate_stylesheet
        if format == :html && serializer
          cssfile = find_template template_path(css_file)
          serializer.serialize(css_file, File.read(cssfile))
        end
        true
      end
      
      def generate_index
        if format == :html && serializer
          serializer.serialize 'index.html', render(:index)
        end
        true
      end
      
      def generate_navigation
        if format == :html && serializer
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