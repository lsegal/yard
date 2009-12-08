require 'optparse'

module YARD
  module CLI
    # A tool to view documentation in the console like `ri`
    class YRI
      # Helper method to run the utility on an instance.
      # @see #run
      def self.run(*args) new.run(*args) end
        
      def initialize
        @search_paths = [YARD::ROOT + '/../.yardoc']
        add_gem_paths
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
      
      def print_object(object)
        if object.type == :method && object.is_alias?
          tmp = P(object.namespace, (object.scope == :instance ? "#" : "") + 
            object.namespace.aliases[object].to_s) 
          object = tmp unless YARD::CodeObjects::Proxy === tmp
        end
        object.format(:serializer => @serializer)
      end
      
      def find_object(name)
        @search_paths.each do |path|
          Registry.clear
          Registry.load(path)
          obj = Registry.at(name)
          return obj if obj
        end
        nil
      end
      
      private
      
      def add_gem_paths
        require 'rubygems'
        Gem.source_index.find_name('').each do |spec|
          if yfile = Registry.yardoc_file_for_gem(spec.name)
            @search_paths << yfile
          end
        end
      rescue LoadError
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
        
        opts.separator ""
        opts.separator "Other options:"
        opts.on_tail('-q', '--quiet', 'Show no warnings') { log.level = Logger::ERROR }
        opts.on_tail('--verbose', 'Show debugging information') { log.level = Logger::DEBUG }
        opts.on_tail('-v', '--version', 'Show version.') { puts "yard #{YARD::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help.')  { puts opts; exit }

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