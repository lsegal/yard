module YARD
  module CLI
    # A command-line utility to generate Graphviz graphs from
    # a set of objects
    # 
    # @see YardGraph#run
    class YardGraph < Base
      # The options parsed out of the commandline.
      # Default options are:
      #   :format => :dot,
      #   :visibilities => [:public]
      attr_reader :options
      
      # The set of objects to include in the graph.
      attr_reader :objects

      # Helper method to run the utility on an instance.
      # @see #run
      def self.run(*args) new.run(*args) end
        
      # Creates a new instance of the command-line utility
      def initialize
        super
        @serializer = YARD::Serializers::StdoutSerializer.new
        @options = SymbolHash[
          :format => :dot,
          :visibilities => [:public]
        ]
      end
      
      # Runs the command-line utility.
      # 
      # @example
      #   grapher = YardGraph.new
      #   grapher.run('--private')
      # @param [Array<String>] args each tokenized argument
      def run(*args)
        Registry.load
        optparse(*args)
        
        contents = objects.map {|o| o.format(options) }.join("\n")
        Templates::Engine.render(:format => :dot, :type => :layout, 
          :serializer => @serializer, :contents => contents) 
      end
      
      private
      
      # Parses commandline options.
      # @param [Array<String>] args each tokenized argument
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
          options[:visibilities].delete(:public)
        end

        opts.on('--protected', "Show or don't show protected methods. (default hides protected)") do
          options[:visibilities].push(:protected)
        end

        opts.on('--private', "Show or don't show private methods. (default hides private)") do 
          options[:visibilities].push(:private) 
        end

        opts.separator ""
        opts.separator "Output options:"

        opts.on('--dot [OPTIONS]', 'Send the results direclty to `dot` with optional arguments.') do |dotopts|
          @serializer = Serializers::ProcessSerializer.new('dot ' + dotopts.to_s)
        end
        
        opts.on('-f', '--file [FILE]', 'Writes output to a file instead of stdout.') do |file|
          @serializer = Serializers::FileSystemSerializer.new(:basepath => '.', :extension => nil)
          @serializer.instance_eval "def serialized_path(object) #{file.inspect} end"
        end
        
        common_options(opts)

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