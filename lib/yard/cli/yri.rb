module YARD
  module CLI
    # A tool to view documentation in the console like `ri`
    class YRI < Base
      CACHE_FILE = File.expand_path('~/.yard/yri_cache')
      SEARCH_PATHS_FILE = File.expand_path('~/.yard/yri_search_paths')
      
      # Helper method to run the utility on an instance.
      # @see #run
      def self.run(*args) new.run(*args) end
        
      def initialize
        super
        @cache = {}
        @search_paths = []
        add_default_paths
        add_gem_paths
        load_cache
        @search_paths.uniq!
      end
        
      # Runs the command-line utility.
      # 
      # @example
      #   YRI.new.run('String#reverse')
      # @param [Array<String>] args each tokenized argument
      def run(*args)
        optparse(*args)
        
        @serializer ||= YARD::Serializers::ProcessSerializer.new('less')
        
        if object = find_object(@name)
          print_object(object)
        else
          STDERR.puts "No documentation for `#{@name}'"
          exit(1)
        end
      end
      
      protected
      
      def cache_object(name, path)
        return if path == Registry.yardoc_file
        @cache[name] = path
        
        File.open!(CACHE_FILE, 'w') do |file|
          @cache.each do |key, value|
            file.puts("#{key} #{value}")
          end
        end
      end
      
      def print_object(object)
        if object.type == :method && object.is_alias?
          tmp = P(object.namespace, (object.scope == :instance ? "#" : "") + 
            object.namespace.aliases[object].to_s) 
          object = tmp unless YARD::CodeObjects::Proxy === tmp
        end
        object.format(:serializer => @serializer)
      end
      
      def find_object(name)
        @search_paths.unshift(@cache[name]) if @cache[name]
        @search_paths.unshift(Registry.yardoc_file)
        
        log.debug "Searching for #{name} in search paths"
        @search_paths.each do |path|
          next unless File.exist?(path)
          log.debug "Searching for #{name} in #{path}..."
          Registry.load(path)
          obj = Registry.at(name)
          if obj
            cache_object(name, path)
            return obj
          end
        end
        nil
      end
      
      private
      
      def load_cache
        return unless File.file?(CACHE_FILE)
        File.readlines(CACHE_FILE).each do |line|
          line = line.strip.split(/\s+/)
          @cache[line[0]] = line[1]
        end
      end
      
      def add_gem_paths
        require 'rubygems'
        Gem.source_index.find_name('').each do |spec|
          if yfile = Registry.yardoc_file_for_gem(spec.name)
            if spec.name =~ /^yard-doc-/
              @search_paths.unshift(yfile)
            else
              @search_paths.push(yfile)
            end
          end
        end
      rescue LoadError
      end
      
      # Adds paths in {SEARCH_PATHS_FILE}
      def add_default_paths
        return unless File.file?(SEARCH_PATHS_FILE)
        paths = File.readlines(SEARCH_PATHS_FILE).map {|l| l.strip }
        @search_paths.push(*paths)
      end
      
      # Parses commandline options.
      # @param [Array<String>] args each tokenized argument
      def optparse(*args)
        opts = OptionParser.new

        opts.separator ""
        opts.separator "General Options:"

        opts.on('-b', '--db FILE', 'Use a specified .yardoc db to search in') do |yfile|
          @search_paths.unshift(yfile)
        end

        opts.on('-T', '--no-pager', 'No pager') do
          @serializer = YARD::Serializers::StdoutSerializer.new
        end
        
        opts.on('-p PAGER', '--pager') do |pager|
          @serializer = YARD::Serializers::ProcessSerializer.new(pager)
        end
        
        common_options(opts)

        begin
          opts.parse!(args)
          @name = args.first
        rescue => e
          STDERR.puts e.message
          STDERR << "\n" << opts
          exit
        end
      end
    end
  end
end