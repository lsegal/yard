class YARD::Handlers::MixinHandler < YARD::Handlers::Base
  handles /\Ainclude\b/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      mixin.strip!
      if mixin =~ /^[A-Z\:]/
        obj = P(namespace, mixin)
        namespace.mixins << obj
        obj.dynamic = true if !obj.is_a?(Proxy) && owner != namespace
      else
        raise YARD::Handlers::UndocumentableError, "mixin #{mixin} for class #{namespace.path}"
      end
    end
  end
end