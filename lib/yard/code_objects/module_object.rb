module YARD::CodeObjects
  class ModuleObject < NamespaceObject
    def initialize(namespace, name)
      super(namespace, name, :class, :module, :class)
    end
  end
end