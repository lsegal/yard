require 'tadpole'

module YARD
  Template = ::Tadpole
  Template.register_template_path(TEMPLATE_ROOT)
  
  module Templates
    def self.render(options = {})
      options[:format] ||= :text
      options[:type] ||= options[:object].type if options[:object]
      options[:template] ||= :default
      options[:serializer] = nil

      mod = Template.template(options[:template], options[:type])
      mod.run(options)
    end
  end
end

module Tadpole
  module SectionProviders
    class SectionProvider
      def self.provides?(object, basename) 
        self.const_get("EXTENSIONS").any? do |ext|
          extra = self == TemplateProvider ? "" : ".#{object.format.to_s}"
          path = basename + extra + ext
          if path_suitable?(path) 
            object.extend(Generators::Helpers::BaseHelper)
            object.extend(Generators::Helpers::HtmlHelper) if object.format == :html
            return path
          end
        end
        nil
      end
    end
  end
end