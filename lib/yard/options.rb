module YARD
  # Generalized options class for passing around large amounts of options between objects.
  # 
  # Although the options class allows for Hash-like access (+opts[:key]+), the recommended
  # mechanism for accessing an option key will be via standard method calls on attributes
  # 
  # The options class exists for better visibility and documentability of options being
  # passed through to other objects. Because YARD has parser and template architectures
  # that are heavily reliant on options, it is necessary to make these option keys easily
  # visible and understood by developers. Since the options class is more than just a
  # basic Hash, the subclass can provide aliasing and convenience methods to simplify
  # option property access, and, if needed, support backward-compatibility for deprecated
  # key names.
  # 
  # @abstract Subclasses should define (and document) custom attributes that are expected
  #   to be made available as option keys.
  # @example Defining an Options class with custom option keys
  #   class TemplateOptions < YARD::Options
  #     # @return [Symbol] the output format to generate templates in
  #     attr_accessor :format
  #
  #     # @return [Symbol] the template to use when generating output
  #     attr_accessor :template
  #   end
  # @example Initializing default option values
  #   class TemplateOptions < YARD::Options
  #     def initialize
  #       super
  #       self.format = :html
  #       self.template = :default
  #       self.highlight = true
  #       # ...
  #     end
  #   end
  # @example Using +default_attr+ to create default attributes
  #   class TemplateOptions < YARD::Options
  #     default_attr :format, :html
  #     default_attr :template, :default
  #     default_attr :highlight, true
  #   end
  # @example Deprecating an option while still supporting it
  #   class TemplateOptions < YARD::Options
  #     # @return [Boolean] if syntax highlighting should be performed on code blocks.
  #     #   Defaults to true.
  #     attr_accessor :highlight
  # 
  #     # @deprecated Use {#highlight} instead.
  #     # @return [Boolean] if no syntax highlighting should be performs on code blocks.
  #     #   Defaults to false.
  #     attr_accessor :no_highlight
  #     def no_highlight=(value) @highlight = !value end
  #     def no_highlight; !highlight end
  #   end
  class Options
    # @macro [attach] yard.default_attr
    #   @attribute $1
    # Defines an attribute named +key+ and sets a default value for it
    # 
    # @example Defining a default option key
    #   default_attr :name, 'Default Name'
    #   default_attr :time, lambda { Time.now }
    # @param [Symbol] key the option key name
    # @param [Object, Proc] default the default object value. If the default
    #   value is a proc, it is executed upon initialization.
    def self.default_attr(key, default)
      (@defaults ||= {})[key] = default
      attr_accessor(key)
    end
    
    def initialize
      set_defaults
    end
    
    # Delegates calls with Hash syntax to actual method with key name
    # 
    # @example Calling on an option key with Hash syntax
    #   options[:format] # equivalent to: options.format
    # @param [Symbol, String] key the option name to access
    # @return the value of the option named +key+
    def [](key) send(key) end

    # Delegates setter calls with Hash syntax to the attribute setter with the key name
    # 
    # @example Setting an option with Hash syntax
    #   options[:format] = :html # equivalent to: options.format = :html
    # @param [Symbol, String] key the optin to set
    # @param [Object] value the value to set for the option
    # @return [Object] the value being set
    def []=(key, value) send("#{key}=", value) end
    
    # Updates values from an options hash or object on this object
    # 
    # @param [Options, Hash] opts
    # @return [self]
    def update(opts)
      opts = opts.to_hash if Options === opts
      opts.each do |key, value|
        self[key] = value if respond_to?("#{key}=")
      end
      self
    end
    
    # Creates a new options object and sets options hash or object value
    # onto that object.
    # 
    # @param [Options, Hash] opts
    # @return [Options] the newly created options object
    def merge(opts)
      self.class.new.update(opts)
    end
    
    # @return [Hash] Converts options object to an options hash. All keys
    #   will be symbolized.
    def to_hash
      opts = {}
      instance_variables.each do |ivar|
        name = ivar.to_s.sub(/^@/, '')
        opts[name.to_sym] = send(name) if respond_to?(name)
      end
      opts
    end
    
    unless defined? tap() # only for 1.8.6
      def tap(&block) yield(self); self end
    end
    
    private
    
    def set_defaults
      defaults = self.class.instance_variable_get("@defaults")
      return unless defaults
      defaults.each do |key, value|
        self[key] = Proc === value ? value.call : value
      end
    end
  end
end
