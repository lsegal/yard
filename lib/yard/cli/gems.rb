module YARD
  module CLI
    class Gems < Command
      def initialize
        @rebuild = false
        @gems = []
      end
      
      def description; "Builds YARD index for gems" end
      
      # Runs the commandline utility, parsing arguments and generating
      # YARD indexes for gems.
      # 
      # @param [Array<String>] args the list of arguments
      # @return [void] 
      def run(*args)
        optparse(*args)
        @gems += Gem.source_index.find_name('') if @gems.empty?
        build_gems
      end
      
      private
      
      # Builds .yardoc files for all non-existing gems
      # @param [Array] gems
      def build_gems
        require 'rubygems'
        @gems.each do |spec|
          ver = "= #{spec.version}"
          dir = Registry.yardoc_file_for_gem(spec.name, ver)
          if dir && File.directory?(dir) && !@rebuild
            log.debug "#{spec.name} index already exists at '#{dir}'"
          else
            yfile = Registry.yardoc_file_for_gem(spec.name, ver, true)
            next unless yfile
            next unless File.directory?(spec.full_gem_path)
            Registry.clear
            Dir.chdir(spec.full_gem_path)
            log.info "Building yardoc index for gem: #{spec.full_name}"
            Yardoc.run('-n', '-b', yfile)
          end
        end
      end
      
      def add_gems(gems)
        gems.each_slice(2) do |gem, ver_require|
          specs = Gem.source_index.find_name(gem, ver_require || ">= 0")
          @gems += specs unless specs.empty?
        end
      end
      
      # Parses options
      def optparse(*args)
        opts = OptionParser.new
        opts.banner = 'Usage: yard gems [options] [gem_name [version]]'
        opts.separator ""
        opts.separator "#{description}. If no gem_name is given,"
        opts.separator "all gems are built."
        opts.separator ""
        opts.on('--rebuild', 'Rebuilds index') do
          @rebuild = true
        end
        opts.on('--legacy', 'Use old style parser and handlers. Unavailable under Ruby 1.8.x') do
          YARD::Parser::SourceParser.parser_type = :ruby18
        end
        
        common_options(opts)
        parse_options(opts, args)
        add_gems(args)
      end
    end
  end
end