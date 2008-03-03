module YARD::CodeObjects
  class ClassObject < NamespaceObject
    def initialize(namespace, name)
      super(namespace, name, :class, :public, :class)
    end
  end
end