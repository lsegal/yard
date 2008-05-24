require 'rubygems'
require 'erubis'

module YARD
  module Generators
    class Base
      class << self
        def template_paths
          @template_paths ||= [TEMPLATE_ROOT]
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

      attr_reader :format, :template, :verifier
      attr_reader :serializer, :ignore_serializer
      attr_reader :options
      attr_reader :current_object
      
      def initialize(opts = {})
        opts = SymbolHash[
          :format => :html,
          :template => :default,
          :serializer => nil,
          :verifier => nil
        ].update(opts)
        
        @options = opts
        @format = options[:format]
        @template = options[:template] 
        @serializer = options[:serializer] 
        @ignore_serializer = options[:ignore_serializer]
        @verifier = options[:verifier]
      end
      
      def generator_name
        self.class.to_s.split("::").last.gsub(/Generator$/, '').downcase
      end
      
      def generate(*list, &block)
        output = ""
        serializer.before_serialize if serializer && !ignore_serializer
        list.flatten.each do |object|
          next unless object && object.is_a?(CodeObjects::Base)
          
          objout = ""
          @current_object = object

          next if call_verifier(object).is_a?(FalseClass)
          
          objout << render_sections(object, &block) 

          if serializer && !ignore_serializer && !objout.empty?
            serializer.serialize(object, objout) 
          end
          output << objout
        end
        
        if serializer && !ignore_serializer
          serializer.after_serialize(output) 
        end
        output
      end
      
      protected
      
      def call_verifier(object)
        if verifier.is_a?(Symbol)
          send(verifier, object)
        elsif verifier.respond_to?(:call)
          verifier.call(object)
        end
      end
      
      def sections_for(object); [] end
      
      def before_section(object)
        extend Helpers::BaseHelper
        extend Helpers::HtmlHelper if format == :html
      end

      def render_sections(object, sections = nil)
        sections ||= sections_for(object) || []

        data = ""
        sections.each_with_index do |section, index|
          next if section.is_a?(Array)
          
          data << if sections[index+1].is_a?(Array)
            render_section(section, object) do |obj|
              tmp, @current_object = @current_object, obj
              out = render_sections(obj, sections[index+1])
              @current_object = tmp
              out
            end
          else
            render_section(section, object)
          end
        end
        data
      end

      def render_section(section, object, &block)
        return "" if before_section(object).is_a?(FalseClass)
        
        begin
          if section.is_a?(Class) && section <= Generators::Base
            opts = options.dup
            opts.update(:ignore_serializer => true)
            sobj = section.new(opts)
            sobj.generate(object, &block)
          elsif section.is_a?(Generators::Base)
            sobj.generate(object, &block)
          elsif section.is_a?(Symbol)
            if respond_to?(section)
              send(section, object, &block) || ""
            else # treat it as a String
              render(object, section, &block)
            end
          elsif section.is_a?(String)
            render(object, section, &block)
          else
            raise ArgumentError
          end
        rescue ArgumentError
          type = section <= Generators::Base ? "generator" : "section"
          log.warn "Ignoring invalid #{type} '#{section}' in #{self.class}"
          ""
        rescue => e
          log.error "In generator #{self.class.name}, section #{section}:"
          log.error "\tFailed to parse object: " + object.inspect
          log.error "\tException message: " + e.message
          log.error "\n\t" + e.backtrace[0..5].join("\n\t")
          log.error ""
          raise
        end
      end
      
      def render(object, file = nil, generator = generator_name, &block)
        path = template_path(file, generator)
        f = find_template(path)
        if f
          begin
            Erubis::Eruby.new(File.read(f)).result(binding)
          rescue => e
            log.error "In generator #{self.class.name}, rendering: #{path}:"
            log.error "\tFailed to parse object: " + object.inspect
            log.error "\tException message: " + e.message
            log.error "\n\t" + e.backtrace[0..5].join("\n\t")
            log.error ""
            raise
          end
        else
          log.warn "Cannot find template `#{path}`"
          ""
        end
      end
      
      def template_path(meth, generator = generator_name)
        File.join(template.to_s, generator, format.to_s, meth.to_s + ".erb")
      end
      
      def find_template(path)
        self.class.template_paths.each do |basepath| 
          f = File.join(basepath, path)
          return f if File.file?(f)
        end
        nil
      end
    end
  end
end