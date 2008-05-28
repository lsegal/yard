require 'rubygems'
require 'erubis'

module YARD
  module Generators
    class Base
      include Helpers::FilterHelper

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
        
        def before_section(*args)
          if args.size == 1
            before_section_filters.push [nil, args.first]
          elsif args.size == 2
            before_section_filters.push(args)
          else
            raise ArgumentError, "before_section takes a generator followed by a Proc/lambda or Symbol referencing the method name"
          end
        end
        
        def before_section_filters
          @before_section_filters ||= []
        end
        
        def before_generate(meth)
          before_generate_filters.push(meth)
        end
        
        def before_generate_filters
          @before_generate_filters ||= []
        end
      end
      
      # Creates a generator by adding extra options
      # to the options hash. 
      # 
      # @example [Creates a new MethodSummaryGenerator for public class methods]
      #   G(MethodSummaryGenerator, :scope => :class, :visibility => :public)
      # 
      # @param [Class] generator 
      #   the generator class to use.
      # 
      # @options opts
      #   :ignore_serializer -> true => value
      #
      # 
      def G(generator, opts = {})
        opts = SymbolHash[:ignore_serializer => true].update(opts)
        generator.new(options, opts)
      end

      attr_reader :format, :template, :verifier
      attr_reader :serializer, :ignore_serializer
      attr_reader :options
      attr_reader :current_object
      
      def initialize(opts = {}, extra_opts = {})
        opts = SymbolHash[
          :format => :html,
          :template => :default,
          :serializer => nil,
          :verifier => nil
        ].update(opts).update(extra_opts)
        
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
          next if run_before_generate(object).is_a?(FalseClass)
          
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
      
      def run_before_generate(object)
        self.class.before_generate_filters.each do |meth|
          meth = method(meth) if meth.is_a?(Symbol)
          result = meth.call *(meth.arity == 0 ? [] : [object])
          return result if result.is_a?(FalseClass)
        end
      end

      def run_before_sections(section, object)
        result = before_section(section, object)
        return result if result.is_a?(FalseClass)
        
        self.class.before_section_filters.each do |info|
          result, sec, meth = nil, *info
          if sec.nil? || sec == section
            meth = method(meth) if meth.is_a?(Symbol)
            args = [section, object]
            if meth.arity == 1 
              args = [object]
            elsif meth.arity == 0
              args = []
            end

            result = meth.call(*args)
            log.debug("Calling before section filter for %s%s with `%s`, result = %s" % [
              self.class.to_s.split("::").last, section.inspect, object, 
              result.is_a?(FalseClass) ? 'fail' : 'pass'
            ])
          end

          return result if result.is_a?(FalseClass)
        end
      end
      
      def sections_for(object); [] end
      
      def before_section(section, object)
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
        begin
          if section.is_a?(Class) && section <= Generators::Base
            opts = options.dup
            opts.update(:ignore_serializer => true)
            sobj = section.new(opts)
            sobj.generate(object, &block)
          elsif section.is_a?(Generators::Base)
            section.generate(object, &block)
          elsif section.is_a?(Symbol) || section.is_a?(String)
            return "" if run_before_sections(section, object).is_a?(FalseClass)

            if section.is_a?(Symbol)
              if respond_to?(section)
                if method(section).arity != 1
                  send(section, &block)
                else
                  send(section, object, &block) 
                end || ""
              else # treat it as a String
                render(object, section, &block)
              end
            else
              render(object, section, &block)
            end
          else
            type = section.is_a?(String) || section.is_a?(Symbol) ? 'section' : 'generator'
            log.warn "Ignoring invalid #{type} '#{section}' in #{self.class}"
            ""
          end
        end
      end
      
      def render(object, file = nil, locals = {}, &block)
        _path = template_path(file, generator_name)
        _f = find_template(_path)
        if _f
          __l = locals.map {|k,v| "#{k} = #{v.inspect}" }.join(";")
          Erubis::Eruby.new("<% #{__l} %>" + File.read(_f)).result(binding)
        else
          log.warn "Cannot find template `#{_path}`"
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