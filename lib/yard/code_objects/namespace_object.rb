module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children
    
    def initialize(namespace, name, *args)
      super
      @children = []
    end
  end
end