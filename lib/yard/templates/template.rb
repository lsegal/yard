require 'erb'

module YARD
  module Templates
    module Template
      attr_accessor :class, :options, :subsections, :section
      
      class << self
        attr_accessor :extra_includes

        def included(klass)
          klass.extend(ClassMethods)
        end
      end
      
      self.extra_includes = []
      
      include Helpers::BaseHelper
      include Helpers::MethodHelper

      module ClassMethods
        attr_accessor :path, :full_path
        
        def full_paths
          included_modules.inject([full_path]) do |paths, mod|
            paths |= mod.full_paths if mod.respond_to?(:full_paths)
            paths
          end
        end
    
        def initialize(path, full_path)
          self.path = path
          self.full_path = Pathname.new(full_path)
          include_parent
          load_setup_rb
        end
    
        def load_setup_rb
          setup_file = File.join(full_path, 'setup.rb')
          if File.file? setup_file
            module_eval(File.read(setup_file).taint, setup_file, 1)
          end
        end
        
        def include_parent
          pc = path.to_s.split('/')
          if pc.size > 1
            include Engine.template!(pc.pop, full_path.join('..').cleanpath)
          end
        end
      
        def new(*args)
          obj = Object.new.extend(self)
          obj.class = self
          obj.send(:initialize, *args)
          obj
        end
      
        def run(*args)
          new(*args).run
        end
      
        def T(*path)
          Engine.template(self, *path)
        end
      
        def is_a?(klass)
          return true if klass == Template
          super(klass)
        end

        def find_file(basename)
          full_paths.each do |path|
            file = path.join(basename)
            return file if file.file?
          end

          nil
        end
      end
    
      def initialize(opts = {})
        @cache, @cache_filename = {}, {}
        @sections, @options = [], {}
        add_options(opts)
        
        extend(Helpers::HtmlHelper) if options[:format] == :html
        extend(*Template.extra_includes) unless Template.extra_includes.empty?

        init
      end
    
      def T(*path)
        path.push(options[:format]) if options[:format]
        self.class.T(*path)
      end
    
      def sections(*args)
        @sections.replace(args) if args.size > 0
        @sections
      end
      
      def subsections=(value)
        @subsections = Array === value ? value : nil
      end
    
      def init
      end
    
      def run(opts = nil, sects = sections, start_at = 0, break_first = false, &block)
        out = ""
        return out if sects.nil?
        sects = sects[start_at..-1] if start_at > 0
        add_options(opts) do
          sects.each_with_index do |s, index|
            next if Array === s
            self.section = s
            self.subsections = sects[index + 1]
            subsection_index = 0
            value = render_section(section) do |*args|
              value = with_section do
                run(args.first, subsections, subsection_index, true, &block)
              end
              subsection_index += 1 
              subsection_index += 1 until !subsections[subsection_index].is_a?(Array)
              value
            end
            out << (value || "")
            break if break_first
          end
        end
        out
      end
          
      def yieldall(opts = nil, &block)
        log.debug "Templates: yielding from #{inspect}"
        with_section { run(opts, subsections, &block) }
      end
    
      def erb(section, &block)
        erb = ERB.new(cache(section), nil, '<>')
        erb.filename = cache_filename(section).to_s
        erb.result(binding, &block)
      end
      
      def file(basename)
        file = self.class.find_file(basename)
        raise ArgumentError, "no file for '#{basename}' in #{self.class.path}" unless file
        file.read
      end
      
      def options=(value)
        @options = value
        set_ivars
      end
      
      def inspect
        "Template(#{self.class.path}) [section=#{section}]"
      end
    
      protected
    
      def erb_file_for(section)
        "#{section}.erb"
      end
    
      private
    
      def render_section(section, &block)
        log.debug "Templates: inside #{self.inspect}"
        case section
        when String, Symbol
          if respond_to?(section)
            send(section, &block) 
          else
            erb(section, &block)
          end
        when Module, Template
          section.run(options, &block) if section.is_a?(Template)
        end || ""
      end

      def cache(section)
        content = @cache[section.to_sym]
        return content if content
      
        file = self.class.find_file(erb_file_for(section))
        @cache_filename[section.to_sym] = file
        raise ArgumentError, "no template for section '#{section}' in #{self.class.path}" unless file
        @cache[section.to_sym] = file.read
      end
      
      def cache_filename(section)
        @cache_filename[section.to_sym]
      end
      
      def set_ivars
        options.each do |k, v|
          instance_variable_set("@#{k}", v)
        end
      end
    
      def add_options(opts = nil)
        return(yield) if opts.nil? && block_given?
        cur_opts = options if block_given?
        
        self.options = options.merge(opts)
      
        if block_given?
          value = yield
          self.options = cur_opts 
          value
        end
      end
      
      def with_section(&block)
        s1, s2 = section, subsections
        value = yield
        self.section, self.subsections = s1, s2
        value
      end
    end
  end
end

