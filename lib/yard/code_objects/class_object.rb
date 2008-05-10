module YARD::CodeObjects
  class ClassObject < NamespaceObject
    attr_accessor :subclasses, :superclass
    
    def initialize(namespace, name, *args, &block)
      @subclasses = CodeObjectList.new(self)
      @superclass = P(nil, Object)
      super
    end
  end
end