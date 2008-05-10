module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children, :mixins
    
    def initialize(namespace, name, *args, &block)
      super
      @children = []
      @mixins = []
    end
    
    def mixins=(mixin)
      log.warning "Do not use #mixins= to add mixins, use #add_mixin instead."
      add_mixin(mixin)
    end
    
    def add_mixin(mixin)
      if mixin.is_a? NamespaceObject
        @mixins << mixin
      elsif mixin.is_a?(String) || mixin.is_a?(Symbol)
        @mixins << P(namespace, mixin) 
      else
        raise ArgumentError, "#{mixin.class} is not a valid module or namespace"
      end
    end
  end
end