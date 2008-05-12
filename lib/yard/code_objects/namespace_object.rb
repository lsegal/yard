module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children, :mixins
    attr_accessor :cvars, :ivars, :methods
    
    def initialize(namespace, name, *args, &block)
      @children = CodeObjectList.new(self)
      @mixins = CodeObjectList.new(self)
      @cvars = CodeObjectList.new(self)
      @ivars = CodeObjectList.new(self)
      @methods = CodeObjectList.new(self)
      super
    end
  end
end