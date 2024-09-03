module YARD
  # An OpenStruct compatible struct class that allows for basic access of attributes
  # via +struct.attr_name+ and +struct.attr_name = value+.
  class OpenStruct
    def initialize(hash = {})
      @table = hash.each_pair { |k, v| [k.to_sym, v] }
    end

    # @private
    def method_missing(name, *args)
      if name.to_s.end_with?('=')
        varname = name.to_s[0..-2].to_sym
        __cache_lookup__(varname)
        self[varname] = args.first
      else
        __cache_lookup__(name)
        self[name]
      end
    end

    def to_h
      @table.dup
    end

    def ==(other)
      other.is_a?(self.class) && to_h == other.to_h
    end

    def hash
      @table.hash
    end

    def dig(*keys)
      @table.dig(*keys)
    end

    def []=(key, value)
      @table[key.to_sym] = value
    end

    def [](key)
      @table[key.to_sym]
    end

    def each_pair(&block)
      @table.each_pair(&block)
    end

    def marshal_dump
      @table
    end

    def marshal_load(data)
      @table = data
    end

    private

    def __cache_lookup__(name)
      instance_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}; @table[:#{name}]; end
        def #{name}=(v); @table[:#{name}] = v; end
      RUBY
    end
  end
end
