require 'optparse'

module YARD
  module CLI
    class Yardoc
      attr_reader :options, :visibilities
      attr_accessor :files, :reload, :generate
      
      def self.run(*args) new.run(*args) end
        
      def initialize
        @options = SymbolHash[
          :format => :html, 
          :template => :default, 
          :serializer => YARD::Serializers::FileSystemSerializer.new, 
          :readme => ['README', 'README.txt'],
          :verifier => lambda do |gen, obj| 
            return false if gen.respond_to?(:visibility) && !visibilities.include?(gen.visibility) 
          end
        ]
        @visibilities = [:public]
        @reload = true
        @generate = true
        @files = ['lib/**/*.rb']
      end
      
      def run(*args)
        optparse(*args)
        Registry.load(files, reload)
        
        if generate
          Generators::FullDocGenerator.new(options).generate Registry.all(:module, :class)
        end
      end
      
      private
      
      def optparse(*args)
        serialopts = SymbolHash.new
        
        opts = OptionParser.new
        opts.banner = "Usage: yardoc [options] [source files]"

        opts.separator "(if a list of source files is omitted, lib/**/*.rb is used.)"
        opts.separator ""
        opts.separator "General Options:"

        opts.on('-c', '--use-cache', 
                'Use the cached .yardoc database to generate documentation. (defaults to no cache)') do 
          self.reload = false
        end
        
        opts.on('-n', '--no-output', 'Only generate .yardoc database, no documentation.') do
          self.generate = false
        end
        
        opts.on('-e', '--load FILE', 'A Ruby script to load before the source tree is parsed.') do |file|
          if !require(file.gsub(/\.rb$/, ''))
            log.error "The file `#{file}' was already loaded, perhaps you need to specify the absolute path to avoid name collisions."
            exit
          end
        end

        opts.separator ""
        opts.separator "Output options:"
  
        opts.on('--no-public', "Don't show public methods. (default shows public)") do 
          visibilities.delete(:public)
        end

        opts.on('--protected', "Show or don't show protected methods. (default hides protected)") do
          visibilities.push(:protected)
        end

        opts.on('--private', "Show or don't show private methods. (default hides private)") do 
          visibilities.push(:private) 
        end
        
        opts.on('-r', '--readme FILE', 'The readme file used as the title page of documentation.') do |readme|
          options[:readme] = readme
        end
        
        opts.on('-d', '--output-dir PATH', 
                'The output directory. (defaults to ./doc)') do |dir|
          serialopts[:basepath] = dir
        end

        opts.on('-t', '--template TEMPLATE', 
                'The template to use. (defaults to "default")') do |template|
          options[:template] = template.to_sym
        end

        opts.on('-p', '--template-path PATH', 
                'The template path to look for templates in. (used with -t).') do |path|
          YARD::Generator::Base.register_template_path(path)
        end
        
        opts.on('-f', '--format FORMAT', 
                'The output format for the template. (defaults to html)') do |format|
          options[:format] = format
        end

        opts.separator ""
        opts.separator "Other options:"
        opts.on_tail('-q', '--quiet', 'Show no warnings.') { log.level = Logger::ERROR }
        opts.on_tail('--verbose', 'Show debugging information.') { log.level = Logger::DEBUG }
        opts.on_tail('-v', '--version', 'Show version.') { puts "yard #{YARD::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help.')  { puts opts; exit }
        
        begin
          opts.parse!(args)
        rescue OptionParser::InvalidOption => e
          STDERR.puts e.message
          STDERR << "\n" << opts
          exit
        end
        
        # Last minute modifications
        self.files = args unless args.empty?
        self.reload = false if self.files.empty?
        visibilities.uniq!
        options[:serializer] = Serializers::FileSystemSerializer.new(serialopts)
      end
    end
  end
end