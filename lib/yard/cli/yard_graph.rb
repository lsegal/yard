require 'optparse'

module YARD
  module CLI
    class YardGraph
      attr_reader :options
      
      def self.run(*args) new.run(*args) end
        
      def initialize
        @options = SymbolHash[
          :format => :dot, 
          :template => :default, 
          :serializer => YARD::Serializers::StdoutSerializer.new
        ]
      end
      
      def run(*args)
        optparse(*args)
        Registry.load
        Generators::UMLGenerator.new(options).generate Registry.root
      end
      
      private
      
      def optparse(*args)
        opts = OptionParser.new
        opts.on('--empty-nodes', 
                'Show empty nodes in graph (GraphViz hides subgraphs if they have no children).') do 
          options[:empty_nodes] = true
        end
        
        opts.on('--full', 'Full class diagrams (show methods and attributes).') do
          options[:full] = true
        end

        opts.on('-d', '--dependencies', 'Show mixins in dependency graph.') do
          options[:dependencies] = true
        end
        
        opts.on('--dot [OPTIONS]', 'Send the results direclty to `dot` with optional arguments.') do |dotopts|
          options[:serializer] = Serializers::ProcessSerializer.new('dot ' + dotopts.to_s)
        end
        
        opts.on('-f', '--file [FILE]', 'Writes output to a file instead of stdout.') do |file|
          options[:serializer] = Serializers::FileSystemSerializer.new(:basepath => '.', :extension => nil)
          options[:serializer].instance_eval "def serialized_path(object) #{file.inspect} end"
        end

        opts.on('-t', '--template [TEMPLATE]', 
                'The template to use (defaults to "default")') do |template|
          options[:template] = template.to_sym
        end
        
        opts.on_tail('-q', '--quiet', 'Show no warnings') { log.level = Logger::ERROR }
        opts.on_tail('--verbose', 'Show debugging information') { log.level = Logger::DEBUG }
        opts.on_tail('-v', '--version', 'Show version.') { puts "yard #{YARD::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help.')  { puts opts; exit }

        begin
          opts.parse!(args)
        rescue => e
          STDERR.puts e.message
          STDERR << "\n" << opts
          exit
        end
      end
    end
  end
end