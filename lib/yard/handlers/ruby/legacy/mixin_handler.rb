class YARD::Handlers::Ruby::Legacy::MixinHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /\Ainclude(\s|\()/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      process_mixin(mixin.strip)
    end
  end

  private

  def process_mixin(mixin)
    unless mixmatch = mixin[/\A(#{NAMESPACEMATCH})/, 1]
      raise YARD::Parser::UndocumentableError, "mixin #{mixin} for class #{namespace.path}"
    end

    obj = Proxy.new(namespace, mixmatch)
    
    case obj
    when Proxy
      obj.type = :module
    when ConstantObject # If a constant is included, use its value as the real object
      obj = Proxy.new(namespace, obj.value)
    end

    namespace.mixins(scope) << obj
  end
end
