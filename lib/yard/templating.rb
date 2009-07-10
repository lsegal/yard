require 'tadpole'

module YARD
  Template = ::Tadpole
  Template.register_template_path(TEMPLATE_ROOT)
  
  module Templates
    def self.render(object, options = {})
      options[:format] ||= :text
      options[:type] ||= object.type
      options[:template] ||= :default
      options[:object] = object
      options[:serializer] = nil

      mod = Template.template(options[:template], options[:format], options[:type])
      mod.send(:include, Generators::Helpers::BaseHelper)
      if options[:format] == :html
        mod.send(:include, Generators::Helpers::HtmlHelper)
      end
      
      mod.run(options)
    end
  end
end
