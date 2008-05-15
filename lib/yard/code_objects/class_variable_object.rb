module YARD::CodeObjects
  class ClassVariableObject < Base
    def initialize(namespace, name, &block)
      super
      self.namespace.cvars << self unless namespace.is_a? Proxy
    end
  end
end