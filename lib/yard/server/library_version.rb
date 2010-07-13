require 'fileutils'

module YARD
  module Server
    class LibraryNotPreparedError < RuntimeError; end
    
    class LibraryVersion
      attr_accessor :name
      attr_accessor :version
      attr_accessor :yardoc_file
      attr_accessor :source
      attr_accessor :source_path
      
      def initialize(name, version = nil, yardoc = nil, source = :disk)
        self.name = name
        self.yardoc_file = yardoc
        self.version = version
        self.source = source
        self.source_path = load_source_path
      end
      
      def to_s(url_format = true)
        version ? "#{name}#{url_format ? '/' : '-'}#{version}" : "#{name}"
      end
      
      def hash; to_s.hash end
      
      def eql?(other)
        other.is_a?(LibraryVersion) && other.name == name && 
          other.version == version && other.yardoc_file == yardoc_file
      end
      alias == eql?
      alias equal? eql?
      
      def prepare!
        return if yardoc_file
        meth = "load_yardoc_from_#{source}"
        send(meth) if respond_to?(meth)
      end
      
      def gemspec
        ver = version ? "= #{version}" : ">= 0"
        Gem.source_index.find_name(name, ver).first
      end
      
      protected

      def load_yardoc_from_disk
        nil
      end
      
      def load_yardoc_from_gem
        require 'rubygems'
        ver = version ? "= #{version}" : ">= 0"
        self.yardoc_file = Registry.yardoc_file_for_gem(name, ver)
        unless yardoc_file && File.directory?(yardoc_file)
          puts "BUILDING GEM!!!"
          Thread.new do
            # Build gem docs on demand
            log.debug "Building gem docs for #{to_s(false)}"
            CLI::Gems.run(name, ver)
            self.yardoc_file = Registry.yardoc_file_for_gem(name, ver)
            FileUtils.touch(File.join(yardoc_file, 'complete'))
          end
        end
        unless yardoc_file && File.exist?(File.join(yardoc_file, 'complete'))
          raise LibraryNotPreparedError
        end
      end
      
      def source_path_for_disk
        File.dirname(yardoc_file)
      end
      
      def source_path_for_gem
        gemspec.full_gem_path if gemspec
      end
      
      private
      
      def load_source_path
        meth = "source_path_for_#{source}"
        send(meth) if respond_to?(meth)
      end
    end
  end
end