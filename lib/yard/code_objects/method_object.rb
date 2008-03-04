module YARD::CodeObjects
  class MethodObject < Base
    attr_accessor :visibility, :scope
    
    def initialize(namespace, name, visibility, scope) 
      super(namespace, name) do |o|
        o.visibility = visibility
        o.scope = scope
        yield(o) if block_given?
      end
    end
    
    protected
    
    def sep; scope == :class ? super : INSTANCE_METHOD_SEPARATOR end
  end
end