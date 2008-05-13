module YARD::CodeObjects
  class NamespaceObject < Base
    attr_accessor :children
    attr_reader :cvars, :methods, :constants, :mixins
    
    def initialize(namespace, name, *args, &block)
      @children = CodeObjectList.new(self)
      @mixins = CodeObjectList.new(self)
      @cvars = CodeObjectList.new(self)
      @methods = CodeObjectList.new(self)
      @constants = CodeObjectList.new(self)
      super
    end
  end
end