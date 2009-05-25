# `extend` works just like `include` except that it always
# mixes the module in in class scope,
# and that it can handle `extend self`.
class YARD::Handlers::Ruby::Legacy::ExtendHandler < YARD::Handlers::Ruby::Legacy::MixinHandler
  handles /\Aextend(\s|\()/

  def scope; :class end

  private

  def process_mixin(mixin)
    if mixin == "self"
      namespace.mixins(scope) << namespace
    else
      super
    end
  end
end
