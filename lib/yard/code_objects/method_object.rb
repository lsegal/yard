module YARD::CodeObjects
  class MethodObject < Base
    protected
    
    def sep
      scope == :class ? super : INSTANCE_METHOD_SEPARATOR
    end
  end
end