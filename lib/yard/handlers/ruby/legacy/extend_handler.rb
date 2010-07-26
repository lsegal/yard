# (see Ruby::ExtendHandler)
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
