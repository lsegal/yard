module YARD
  module Generators
    class FullDocGenerator < Base
      before_generate :is_namespace?
      before_list :setup_options
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
      
      def setup_options
        options[:readme] ||= Dir['{README,README.*}']
      end
    
      def css_file;         'style.css'             end
      def css_syntax_file;  'syntax_highlight.css'  end
      def js_file;          'jquery.js'             end
      def js_app_file;      'app.js'                end
      
      def readme_file
        @readme_file ||= [options[:readme]].flatten.compact.find do |readme|
          File.exists?(readme.to_s)
        end.to_s
      end
      
      def readme_file_exists?; not readme_file.empty?; end
      
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
        if format == :html && serializer && readme_file_exists?
          @contents = File.read(readme_file)
          serializer.serialize 'readme.html', render(:readme)
        end
        true
      end
      
      def readme_markup
        if File.extname(readme_file) =~ /^\.(?:mdown|markdown|markdn|md)$/
          :markdown
        elsif File.extname(readme_file) == ".textile"
          :textile
        elsif @contents =~ /\A#!(\S+)\s*$/ # Shebang support
          markup = $1
          @contents.gsub!(/\A.+?\r?\n/, '')
          markup.to_sym
        else
          :rdoc
        end
      end
    end
  end
end
