# Handles 'extend' call to include modules into the class scope of another
# @see MixinHandler
class YARD::Handlers::Ruby::ExtendHandler < YARD::Handlers::Ruby::MixinHandler
  namespace_only
  handles method_call(:extend)

  def scope; :class end

  private

  def process_mixin(mixin)
    if mixin == s(:var_ref, s(:kw, "self"))
      namespace.mixins(scope) << namespace
    else
      super
    end
    nil
  end
end
