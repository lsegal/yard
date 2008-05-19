require 'rubygems'
require 'erubis'

module YARD
  module Generators
    class Base
      include Helpers::BaseHelper
      
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

      attr_accessor :format, :template, :serializer, :verifier
      attr_reader :options
      
      def initialize(opts = {})
        opts = SymbolHash[
          :format => :html,
          :template => :default,
          :serializer => nil,
          :verifier => nil
        ].update(opts)
        
        @options = opts
        self.format = options[:format]
        self.template = options[:template] 
        self.serializer = options[:serializer]
        self.verifier = options[:verifier]
      end
      
      def generator_name
        self.class.to_s.split("::").last.gsub(/Generator$/, '').downcase
      end

      def generate(*list)
        output = ""
        serializer.before_serialize if serializer
        list.flatten.each do |object|
          objout = ""
          
          if verifier.respond_to?(:call)
            next if verifier.call(object).is_a?(FalseClass)
          end
          
          (sections_for(object) || []).each do |section|
            data = render_section(section, object)
            objout << data
          end

          serializer.serialize(object, objout) if serializer && !objout.empty?
          output << objout
        end
        
        serializer.after_serialize(output) if serializer
        output
      end
      
      protected
      
      def sections_for(object); [] end

      def render_section(section, object)
        begin
          if section.is_a?(Class) && section <= Generators::Base
            opts = options.dup
            opts.update(:serializer => nil)
            sobj = section.new(opts)
            sobj.generate(object)
          elsif section.is_a?(Generators::Base)
            sobj.generate(object)
          elsif section.is_a?(Symbol)
            if respond_to?(section)
              send(section, object)
            else # treat it as a String
              render(object, section)
            end
          elsif section.is_a?(String)
            render(object, section)
          else
            raise ArgumentError
          end
        rescue ArgumentError
          type = section <= Generators::Base ? "generator" : "section"
          log.warn "Ignoring invalid #{type} '#{section}' in #{self.class}"
          ""
        end
      end
      
      def render(object, file = nil)
        path = template_path(file)
        f = find_template(path)
        if f
          begin
            Erubis::Eruby.new(File.read(f)).result(binding)
          rescue => e
            log.error "Failed to parse template `#{path}`:"
            log.error "Exception message: " + e.message
            log.error "\n" + e.backtrace[0..5].join("\n")
            log.error ""
            raise
          end
        else
          log.warn "Cannot find template `#{path}`"
          ""
        end
      end
      
      def template_path(meth)
        File.join(template.to_s, generator_name, format.to_s, meth.to_s + ".erb")
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