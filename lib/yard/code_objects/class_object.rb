module YARD::CodeObjects
  class ClassObject < NamespaceObject
    attr_accessor :superclass
    
    def initialize(namespace, name, *args, &block)
      @superclass = P(:Object)
      super
    end
    
    def inheritance_tree(include_mods = false)
      list = [self] + (include_mods ? mixins : [])
      if superclass.is_a? Proxy
        list << superclass unless superclass == P(:Object)
      elsif superclass.respond_to? :inheritance_tree
        list += superclass.inheritance_tree(include_mods)
      end
      list
    end
    
    def meths(opts = {})
      opts = SymbolHash[:inheritance => true].update(opts)
      list = super(opts)
      
      if opts[:inheritance]
        inheritance_tree[1..-1].each do |superclass|
          next if superclass.is_a?(Proxy)
          list += superclass.meths(opts)
        end
      end
      
      list
    end
    
    def constants(opts = {})
      opts = SymbolHash[:inheritance => true].update(opts)
      list = super
      
      if opts[:inheritance]
        inheritance_tree[1..-1].each do |superclass|
          next if superclass.is_a?(Proxy)
          list += superclass.constants(opts)
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