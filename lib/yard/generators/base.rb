require 'erb'

module YARD
  module Generators
    class Base
      class << self
        def generator_name
          self.class.to_s.gsub(/Generator$/, '').downcase
        end
        
        def template_paths
          @template_paths ||= [YARD_TEMPLATE_ROOT]
        end

        ##
        # Convenience method to registering a template path.
        # Equivalent to calling:
        #   GeneratorName.template_paths.unshift(path)
        # 
        # @param [String] path 
        #   the pathname to look for the template
        # 
        # @see template_paths
        def register_template_path(path)
          template_paths.unshift(path)
        end
      end

      attr_accessor :format, :template, :serializer
      attr_reader :options
      
      def initialize(opts = {})
        opts = SymbolHash.new({
          :format => :html,
          :template => :default,
          :serializer => nil
        }).update(opts)
        
        @options = opts
        self.format = opts[:format]
        self.template = opts[:template]
        self.serializer = opts[:serializer]
      end
      
      def generate(*list)
        output = ""
        serializer.before_serialize if serializer
        list.flatten.each do |object|
          (sections_for(object) || []).each do |section|
            data = render_section(section, object)
            serializer.serialize(object, data) if serializer
            output << data
          end
        end
        serializer.after_serialize if serializer
        output
      end
      
      protected

      def sections_for(object); [] end

      def render_section(section, object)
        begin
          if section == Generators::Base
            opts = options.dup.update(:serializer => nil)
            sobj = section.new(opts)
            sobj.generate(object)
          elsif section.is_a?(Generators::Base)
            sobj.generate(object)
          elsif section.is_a?(Symbol)
            if respond_to?(section)
              send(section, object)
            else
              raise ArgumentError
            end
          elsif section.is_a?(String)
            render(object, section)
          else
            raise ArgumentError
          end
        rescue ArgumentError
          YARD.logger.debug "Ignoring invalid section in #{self.class}"
        end
      end
      
      def render(object, file = nil)
        path = template_path(file)
        ERB.new(File.read(find_template(path))).result(binding)
      end
      
      def template_path(meth)
        File.join(template.to_s, generator_name, format.to_s, meth.to_s + ".erb")
      end
      
      def find_template(path)
        self.class.template_paths.find do |basepath| 
          File.exist? File.join(basepath, path)
        end
      end
    end
  end
end