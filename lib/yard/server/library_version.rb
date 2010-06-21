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
    end
  end
end