require 'optparse'

module YARD
  module CLI
    class YardGraph
      attr_reader :options, :visibilities
      
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
        optparse(*args)
        Registry.load
        Generators::UMLGenerator.new(options).generate Registry.root
      end
      
      private
      
      def optparse(*args)
        opts = OptionParser.new
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

        opts.on('--[no-]public', "Show or don't show public methods (default shows public)") do |value|
          options[:visibility].send(value ? :push : :delete, :public) 
        end

        opts.on('--[no-]protected', "Show or don't show protected methods (default hides protected)") do |value|
          options[:visibility].send(value ? :push : :delete, :protected) 
        end

        opts.on('--[no-]private', "Show or don't show private methods (default hides private)") do |value|
          options[:visibility].send(value ? :push : :delete, :private) 
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