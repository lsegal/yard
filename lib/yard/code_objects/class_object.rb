module YARD::CodeObjects
  class ClassObject < NamespaceObject
    attr_accessor :superclass
    attr_reader :attributes
    
    def initialize(namespace, name, *args, &block)
      @superclass = P(nil, :Object)
      @attributes = SymbolHash.new
      super
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