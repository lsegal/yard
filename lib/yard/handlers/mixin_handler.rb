class YARD::Handlers::MixinHandler < YARD::Handlers::Base
  handles /\Ainclude(\s|\()/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      mixin.strip!
      if mixmatch = mixin[/\A(#{NAMESPACEMATCH})\s*/, 1] 
        obj = Proxy.new(namespace, mixmatch)
        
        case obj
        when Proxy
          obj.type = :module
        when ConstantObject # If a constant is included, use its value as the real object
          obj = Proxy.new(namespace, obj.value)
        end

        namespace.mixins << obj
      else
        raise YARD::Handlers::UndocumentableError, "mixin #{mixin} for class #{namespace.path}"
      end
    end
  end
end