class YARD::Handlers::MixinHandler < YARD::Handlers::Base
  handles /\Ainclude(\s|\()/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      mixin.strip!
      if mixmatch = mixin[/\A(#{NAMESPACEMATCH})\s*/, 1] 
        obj = P(namespace, mixmatch)
        obj.type = :module if obj.is_a?(Proxy)
        namespace.mixins << obj
      else
        raise YARD::Handlers::UndocumentableError, "mixin #{mixin} for class #{namespace.path}"
      end
    end
  end
end