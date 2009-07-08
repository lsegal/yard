require 'optparse'

module YARD
  module CLI
    class Yardoc
      DEFAULT_YARDOPTS_FILE = ".yardopts"
      
      attr_reader :options, :visibilities
      attr_accessor :files, :reload, :generate
      attr_accessor :options_file
      
      def self.run(*args) new.run(*args) end
        
      def initialize
        @options = SymbolHash[
          :format => :html, 
          :template => :default, 
          :serializer => YARD::Serializers::FileSystemSerializer.new, 
          :files => [],
          :verifier => lambda do |gen, obj| 
            return false if gen.respond_to?(:visibility) && !visibilities.include?(gen.visibility) 
          end
        ]
        @files = []
        @visibilities = [:public]
        @reload = true
        @generate = true
        @options_file = DEFAULT_YARDOPTS_FILE
      end
      
      def run(*args)
        args += support_rdoc_document_file!
        optparse(*yardopts)
        optparse(*args)
        Registry.load(files, reload)
        
        if generate
          Generators::FullDocGenerator.new(options).generate(all_objects)
        end
      end

      def all_objects
        Registry.all(:root, :module, :class)
      end
      
      def yardopts
        IO.read(options_file).split(/\s+/)
      rescue Errno::ENOENT
        []
      end
      
      private
      
      def support_rdoc_document_file!
        IO.read(".document").split(/\s+/)
      rescue Errno::ENOENT
        []
      end
      
      def add_extra_files(*files)
        files.map! {|f| f.include?("*") ? Dir.glob(f) : f }.flatten!
        files.each do |file|
          raise Errno::ENOENT, "Could not find extra file: #{file}" unless File.file?(file)
          options[:files] << file
        end
      end
      
      def parse_files(*files)
        self.files = []
        seen_extra_files_marker = false
        
        files.each do |file|
          if file == "-"
            seen_extra_files_marker = true
            next
          end
          
          if seen_extra_files_marker
            add_extra_files(file)
          else
            self.files << file
          end
        end
      end
      
      def optparse(*args)
        serialopts = SymbolHash.new
        
        opts = OptionParser.new
        opts.banner = "Usage: yardoc [options] [source_files [- extra_files]]"

        opts.separator "(if a list of source files is omitted, lib/**/*.rb is used.)"
        opts.separator ""
        opts.separator "Example: yardoc -o documentation/ - FAQ LICENSE"
        opts.separator "  The above example outputs documentation for files in"
        opts.separator "  lib/**/*.rb to documentation/ including the extra files"
        opts.separator "  FAQ and LICENSE."
        opts.separator ""
        opts.separator "A base set of options can be specified by adding a .yardopts"
        opts.separator "file to your base path containing all extra options separated"
        opts.separator "by whitespace."
        opts.separator ""
        opts.separator "General Options:"

        opts.on('-c', '--use-cache [FILE]', 
                'Use the cached .yardoc db to generate documentation. (defaults to no cache)') do |file|
          YARD::Registry.yardoc_file = file if file
          self.reload = false
        end
        
        opts.on('-b', '--db FILE', 'Use a specified .yardoc db to load from or save to. (defaults to .yardoc)') do |yfile|
          YARD::Registry.yardoc_file = yfile
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
        
        opts.on('--legacy', 'Use old style parser and handlers. Unavailable under Ruby 1.8.x') do
          YARD::Parser::SourceParser.parser_type = :ruby18
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

        opts.on('--no-highlight', "Don't highlight code in docs as Ruby.") do 
          options[:no_highlight] = true
        end
        
        opts.on('--title TITLE', 'Add a specific title to HTML documents') do |title|
          options[:title] = title
        end

        opts.on('-r', '--readme FILE', 'The readme file used as the title page of documentation.') do |readme|
          raise Errno::ENOENT, readme unless File.file?(readme)
          options[:readme] = readme
        end
        
        opts.on('--files FILE1,FILE2,...', 'Any extra comma separated static files to be included (eg. FAQ)') do |files|
          add_extra_files *files.split(",")
        end

        opts.on('-m', '--markup MARKUP', 
                'Markup style used in documentation, like textile, markdown or rdoc. (defaults to rdoc)') do |markup|
          options[:markup] = markup.to_sym
        end

        opts.on('-M', '--markup-provider MARKUP_PROVIDER', 
                'Overrides the library used to process markup formatting (specify the gem name)') do |markup_provider|
          options[:markup_provider] = markup_provider.to_sym
        end
        
        opts.on('-o', '--output-dir PATH', 
                'The output directory. (defaults to ./doc)') do |dir|
          options[:serializer] = nil
          serialopts[:basepath] = dir
        end

        opts.on('-t', '--template TEMPLATE', 
                'The template to use. (defaults to "default")') do |template|
          options[:template] = template.to_sym
        end

        opts.on('-p', '--template-path PATH', 
                'The template path to look for templates in. (used with -t).') do |path|
          YARD::Generators::Base.register_template_path(path)
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
        parse_files(*args) unless args.empty?
        self.files = ['lib/**/*.rb'] if self.files.empty?
        self.visibilities.uniq!
        options[:serializer] ||= Serializers::FileSystemSerializer.new(serialopts)
      end
    end
  end
end
