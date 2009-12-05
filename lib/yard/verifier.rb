module YARD
  # Similar to a Proc, but runs a set of Ruby expressions using a small
  # DSL to make tag lookups easier.
  # 
  # The syntax is as follows:
  # * All syntax is Ruby compatible
  # * +object+ (+o+ for short) exist to access the object being verified
  # * +@TAGNAME+ is translated into +object.tag('TAGNAME')+
  # * +@@TAGNAME+ is translated into +object.tags('TAGNAME')+
  # * +object+ can be omitted as target for method calls (it is implied)
  # 
  # @example Create a verifier to check for objects that don't have @private tags
  #   verifier = Verifier.new('!@private')
  #   verifier.call(object) # => true (no @private tag)
  # @example Create a verifier to find any return tag with an empty description
  #   Verifier.new('@return.text.empty?')
  #   # Equivalent to:
  #   Verifier.new('object.tag(:return).text.empty?')
  # @example Check if there are any @param tags
  #   Verifier.new('@@param.empty?')
  #   # Equivalent to:
  #   Verifier.new('object.tags(:param).empty?')
  # @example Using +object+ or +o+ to look up object attributes directly
  #   Verifier.new('object.docstring == "hello world"')
  #   # Equivalent to:
  #   Verifier.new('o.docstring == "hello world"')
  # @example Without using +object+ or +o+
  #   Verifier.new('tag(:return).size == 1 || has_tag?(:author)')
  # @example Specifying multiple expressions
  #   Verifier.new('@return', '@param', '@yield')
  #   # Equivalent to:
  #   Verifier.new('@return && @param && @yield')
  class Verifier
    # Creates a verifier from a set of expressions
    # 
    # @param [Array<String>] expressions a list of Ruby expressions to
    #   parse.
    def initialize(*expressions)
      create_method_from_expressions(expressions.flatten)
    end
    
    # Passes any method calls to the object from the {#call}
    def method_missing(sym, *args, &block)
      if object.respond_to?(sym)
        object.send(sym, *args, &block)
      else
        super
      end
    end

    # Tests the expressions on the object
    # 
    # @param [CodeObjects::Base] object the object to verify
    # @return [Boolean] the result of the expressions
    def call(object)
      modify_nilclass
      @object = object
      retval = __execute ? true : false
      unmodify_nilclass
      retval
    end
    
    protected
    
    # @return [CodeObjects::Base] the current object being tested
    attr_reader :object
    alias o object
    
    private
    
    # Modifies nil to not throw NoMethodErrors. This allows
    # syntax like object.tag(:return).text to work if the #tag
    # call returns nil, which means users don't need to perform
    # stringent nil checking
    # 
    # @return [void] 
    def modify_nilclass
      NilClass.send(:define_method, :method_missing) {|*args| }
    end
    
    # Returns the state of NilClass back to normal
    # @return [void] 
    def unmodify_nilclass
      NilClass.send(:undef_method, :method_missing)
    end
    
    # Creates the +__execute+ method by evaluating the expressions
    # as Ruby code
    # @return [void] 
    def create_method_from_expressions(exprs)
      expr = exprs.flatten.map {|e| "(#{parse_expression(e)})" }.join(" && ")
      
      instance_eval(<<-eof, __FILE__, __LINE__ + 1)
        def __execute; #{expr}; end
      eof
    end
    
    # Parses a single expression, handling some of the DSL syntax.
    # 
    # The syntax "@tag" should be turned into object.tag(:tag),
    # and "@@tag" should be turned into object.tags(:tag)
    # 
    # @return [String] the parsed expression
    def parse_expression(expr)
      expr = expr.gsub(/@@(\w+)/, 'object.tags("\1")')
      expr = expr.gsub(/@(\w+)/, 'object.tag("\1")')
      expr
    end
  end
end