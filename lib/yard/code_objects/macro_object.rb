module YARD::CodeObjects
  # A MacroObject represents a docstring defined through +@macro NAME+ and can be
  # reused by specifying the tag +@macro NAME+. You can also provide the
  # +attached+ type flag to the macro definition to have it attached to the
  # specific DSL method so it will be implicitly reused.
  # 
  # @example Creating a basic named macro
  #   # @macro prop
  #   # @method $1(${3-})
  #   # @return [$2] the value of the $0
  #   property :foo, String, :a, :b
  #   
  #   # @macro prop
  #   property :bar, Numeric, :value
  # 
  # @example Creating a macro that is attached to the method call
  #   # @macro [attach] prop2
  #   # @method $1(value)
  #   property :foo
  #   
  #   # Extra data added to docstring
  #   property :bar
  class MacroObject < Base
    def self.create(macro_name, data, method_object = nil)
      obj = new(:root, macro_name)
      obj.macro_data = data
      obj.method_object = method_object
      obj
    end
    
    attr_accessor :macro_data
    attr_accessor :method_object
    
    def attached?; method_object ? true : false end
    def path; '.macro.' + name.to_s end
    def sep; '.' end
  end
end
