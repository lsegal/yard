module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children, :mixins
    
    def initialize(namespace, name, *args, &block)
      super
      @children = []
      @mixins = []
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