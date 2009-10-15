require 'pathname'

module YARD
  module Templates
    module Engine
      class << self
        attr_accessor :template_paths

        def register_template_path(path)
          template_paths.push Pathname.new(path)
        end
        
        def template(*path)
          from_template = nil
          from_template = path.shift if path.first.is_a?(Template)
          path = path.join('/')
          full_paths = find_template_path(from_template, path)
          
          path = path.gsub('../', '')
          raise ArgumentError, "No such template for #{path}" if full_paths.empty?
          mod = template!(path, full_paths.shift)
          full_paths.each do |full_path|
            mod.send(:include, template!(path, full_path))
          end
          
          mod
        end
        
        def template!(path, full_path = nil)
          full_path ||= path
          name = template_module_name(full_path)
          return const_get(name) rescue NameError 

          mod = const_set(name, Module.new)
          mod.send(:include, Template)
          mod.send(:initialize, path, full_path)
          mod
        end

        def render(options = {})
          options[:format] ||= :text
          options[:type] ||= options[:object].type if options[:object]
          options[:template] ||= :default
          options[:serializer] ||= nil
          
          mod = template(options[:template], options[:type])
          with_serializer(options[:object], options[:serializer]) { mod.run(options) }
        end
        
        def generate(objects, options = {})
          options[:objects] = objects
          template(options[:template], :fulldoc).run(options)
        end

        def with_serializer(object, serializer, &block)
          serializer.before_serialize if serializer
          output = yield
          if serializer
            serializer.serialize(object, output)
            serializer.after_serialize(output)
          end
          output
        end
        
        private

        def find_template_path(from_template, path)
          paths = template_paths.dup
          paths.unshift(from_template.full_path) if from_template
          paths.inject([]) do |acc, tp|
            full_path = tp.join(path).cleanpath
            acc.unshift(full_path) if full_path.directory?
            acc
          end
        end

        def template_module_name(path)
          'Template_' + path.to_s.gsub(/[^a-z0-9]/i, '_')
        end
      end

      self.template_paths = []
    end
    
    Engine.register_template_path(Pathname.new(YARD::ROOT).join('..', 'templates'))
  end
end
