module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children
    
    def initialize(namespace, name, *args, &block)
      super
      @children = []
      @mixins = []
    end
  end
end