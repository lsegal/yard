module YARD
  module Server
    class LibraryVersion
      attr_accessor :name
      attr_accessor :version
      attr_accessor :yardoc_file
      
      def initialize(name, yardoc, version = nil)
        self.name = name
        self.yardoc_file = yardoc
        self.version = version
      end
      
      def to_s
        version ? "#{name}-#{version}" : "#{name}"
      end
      
      def hash; to_s.hash end
      
      def eql?(other)
        other.is_a?(LibraryVersion) && other.name == name && 
          other.version == version && other.yardoc_file == yardoc_file
      end
      alias == eql?
      alias equal? eql?
    end
  end
end