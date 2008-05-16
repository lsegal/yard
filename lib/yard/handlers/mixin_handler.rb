class YARD::Handlers::MixinHandler < YARD::Handlers::Base
  handles /\Ainclude\b/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      mixin.strip!
      if mixin =~ /^[A-Z\:]/
        namespace.mixins << P(namespace, mixin)
      else
        YARD.logger.warn "in #{self.class.name}: Undocumentable mixin #{mixin} for class #{namespace.path}"
      end
    end
  end
end