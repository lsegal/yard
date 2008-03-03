module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children
    
    def initialize(namespace, name, *args, &block)
      super
      @children = []
    end
  end
end