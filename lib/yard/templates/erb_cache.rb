module YARD
  module Templates
    module ErbCache
      def self.method_for(filename)
        @methods ||= {}
        return @methods[filename] if @methods[filename]
        @methods[filename] = name = "_erb_cache_#{@methods.size}"
        module_eval "def #{name}; #{yield.src.gsub(/\A#coding:.*$/, '')}; end", filename
        name
      end

      def self.clear!
        return unless @methods
        @methods.clear
      end
    end
  end
end
