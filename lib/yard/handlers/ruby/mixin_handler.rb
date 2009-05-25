class YARD::Handlers::Ruby::MixinHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles method_call(:include)
  
  def process
    statement.parameters(false).each {|mixin| process_mixin(mixin) }
  end

  protected

  def process_mixin(mixin)
    unless mixin.ref?
      raise YARD::Parser::UndocumentableError, "mixin #{mixin.source} for class #{namespace.path}"
    end
    
    case obj = Proxy.new(namespace, mixin.source)
    when Proxy
      obj.type = :module
    when ConstantObject # If a constant is included, use its value as the real object
      obj = Proxy.new(namespace, obj.value)
    end
    
    namespace.mixins(scope) << obj
  end
end
