module YARD::CodeObjects
  class ClassObject < NamespaceObject
    attr_accessor :superclass
    
    def initialize(namespace, name, *args, &block)
      @superclass = P(:Object)
      super
    end
    
    def inheritance_tree(include_mods = true)
      list = [self]
      if superclass.is_a? Proxy
        list << superclass unless superclass == P(:Object)
      else
        list += superclass.inheritance_tree(include_mods)
      end
      list
    end
    
    def meths(opts = {})
      opts = SymbolHash[:inherited_methods => false].update(opts)
      list = super(opts)
      
      if opts[:inherited_methods]
        inheritance_tree[1..-1].each do |superclass|
          list += superclass.meths(opts)
        end
      end
      
      list
    end
    
    ##
    # Sets the superclass of the object
    # 
    # @param [Base, Proxy, String, Symbol] object: the superclass value
    def superclass=(object)
      case object
      when Base, Proxy, NilClass
        @superclass = object
      when String, Symbol
        @superclass = P(namespace, object)
      else
        raise ArgumentError, "superclass must be CodeObject, Proxy, String or Symbol" 
      end
    end
  end
end