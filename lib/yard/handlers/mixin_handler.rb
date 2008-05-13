class YARD::Handlers::MixinHandler < YARD::Handlers::Base
  handles /\Ainclude\b/
  
  def process
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).each do |mixin|
      namespace.mixins << P(namespace, mixin.strip)
    end
  end
end