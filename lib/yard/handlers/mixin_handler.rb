class YARD::Handlers::MixinHandler < YARD::Handlers::Base
  handles /\Ainclude\b/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      mixin.strip!
      if mixin =~ /\A#{NAMESPACEMATCH}\Z/
        obj = P(namespace, mixin)
        obj.type = :module if obj.is_a?(Proxy)
        namespace.mixins << obj
      else
        raise YARD::Handlers::UndocumentableError, "mixin #{mixin} for class #{namespace.path}"
      end
    end
  end
end