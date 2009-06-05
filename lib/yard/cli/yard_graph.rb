require 'optparse'

module YARD
  module CLI
    class YardGraph
      attr_reader :options, :visibilities
      attr_reader :objects
      
      def self.run(*args) new.run(*args) end
        
      def initialize
        @options = SymbolHash[
          :format => :dot, 
          :template => :default, 
          :serializer => YARD::Serializers::StdoutSerializer.new,
          :visibility => [:public]
        ]
      end
      
      def run(*args)
        Registry.load
        optparse(*args)
        Generators::UMLGenerator.new(options).generate(*objects)
      end
      
      private
      
      def optparse(*args)
        opts = OptionParser.new

        opts.separator ""
        opts.separator "General Options:"

        opts.on('-b', '--db FILE', 'Use a specified .yardoc db to load from or save to. (defaults to .yardoc)') do |yfile|
          YARD::Registry.yardoc_file = yfile
        end

        opts.on('--full', 'Full class diagrams (show methods and attributes).') do
          options[:full] = true
        end

        opts.on('-d', '--dependencies', 'Show mixins in dependency graph.') do
          options[:dependencies] = true
        end
        
        opts.on('--no-public', "Don't show public methods. (default shows public)") do 
          options[:visibility].delete(:public)
        end

        opts.on('--protected', "Show or don't show protected methods. (default hides protected)") do
          options[:visibility].push(:protected)
        end

        opts.on('--private', "Show or don't show private methods. (default hides private)") do 
          options[:visibility].push(:private) 
        end

        opts.separator ""
        opts.separator "Output options:"

        opts.on('--dot [OPTIONS]', 'Send the results direclty to `dot` with optional arguments.') do |dotopts|
          options[:serializer] = Serializers::ProcessSerializer.new('dot ' + dotopts.to_s)
        end
        
        opts.on('-f', '--file [FILE]', 'Writes output to a file instead of stdout.') do |file|
          options[:serializer] = Serializers::FileSystemSerializer.new(:basepath => '.', :extension => nil)
          options[:serializer].instance_eval "def serialized_path(object) #{file.inspect} end"
        end
        
        opts.separator ""
        opts.separator "Other options:"
        opts.on_tail('-q', '--quiet', 'Show no warnings') { log.level = Logger::ERROR }
        opts.on_tail('--verbose', 'Show debugging information') { log.level = Logger::DEBUG }
        opts.on_tail('-v', '--version', 'Show version.') { puts "yard #{YARD::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help.')  { puts opts; exit }

        begin
          opts.parse!(args)
          if args.first
            @objects = args.map {|o| Registry.at(o) }.compact
          else
            @objects = [Registry.root]
          end
        rescue => e
          STDERR.puts e.message
          STDERR << "\n" << opts
          exit
        end
      end
    end
  end
end