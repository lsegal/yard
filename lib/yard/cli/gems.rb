module YARD
  module CLI
    class Gems < Command
      def initialize
        @rebuild = false
      end
      
      def description; "Builds YARD index for gems" end
      
      # Runs the commandline utility, parsing arguments and generating
      # YARD indexes for gems.
      # 
      # @param [Array<String>] args the list of arguments
      # @return [void] 
      def run(*args)
        optparse(*args)
        build_gems
      end
      
      private
      
      # Builds .yardoc files for all non-existing gems
      # @param [Boolean] rebuild Forces rebuild of all gems
      def build_gems
        require 'rubygems'
        Gem.source_index.find_name('').each do |spec|
          reload = true
          dir = Registry.yardoc_file_for_gem(spec.name)
          if dir && File.directory?(dir) && !@rebuild
            log.debug "#{spec.name} index already exists at '#{dir}'"
          else
            yfile = Registry.yardoc_file_for_gem(spec.name, ">= 0", true)
            next unless yfile
            next unless File.directory?(spec.full_gem_path)
            Registry.clear
            Dir.chdir(spec.full_gem_path)
            log.info "Building yardoc index for gem: #{spec.full_name}"
            Yardoc.run('-n', '-b', yfile)
            reload = false
          end
        end
      end
      
      # Parses options
      def optparse(*args)
        opts = OptionParser.new
        opts.on('--rebuild', 'Rebuilds indexes for all gems') do
          @rebuild = true
        end
        opts.on('--legacy', 'Use old style parser and handlers. Unavailable under Ruby 1.8.x') do
          YARD::Parser::SourceParser.parser_type = :ruby18
        end
        
        common_options(opts)
        parse_options(opts, args)
      end
    end
  end
end