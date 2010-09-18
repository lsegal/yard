# Handles the 'include' statement to mixin a module in the instance scope
class YARD::Handlers::Ruby::MixinHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles method_call(:include)
  
  process do
    errors = statement.parameters(false).map {|mixin| process_mixin(mixin) }.compact
    if errors.size > 0
      msg = errors.size == 1 ? " #{errors[0]}" : "s #{errors.join(", ")}"
      raise YARD::Parser::UndocumentableError, "mixin#{msg} for class #{namespace.path}"
    end
  end

  protected

  def process_mixin(mixin)
    return mixin.source unless mixin.ref?
    return mixin.source if mixin.first.type == :ident
    
    case obj = Proxy.new(namespace, mixin.source)
    when Proxy
      obj.type = :module
    when ConstantObject # If a constant is included, use its value as the real object
      obj = Proxy.new(namespace, obj.value)
    end
    
    namespace.mixins(scope).unshift(obj) unless namespace.mixins(scope).include?(obj)
    nil
  end
end
