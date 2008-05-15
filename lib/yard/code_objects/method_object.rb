module YARD::CodeObjects
  class MethodObject < Base
    attr_accessor :visibility, :scope, :signature
    
    def initialize(namespace, name, scope = :instance) 
      self.visibility = :public
      self.scope = scope

      super
    end
    
    def scope=(v) @scope = v.to_sym end
    def visibility=(v) @visibility = v.to_sym end
    
    protected
    
    def sep; scope == :class ? super : ISEP end
  end
end