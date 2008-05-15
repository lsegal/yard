module YARD::CodeObjects
  class ConstantObject < Base
    def initialize(namespace, name, &block)
      super
      self.namespace.constants << self unless namespace.is_a? Proxy
    end
  end
end