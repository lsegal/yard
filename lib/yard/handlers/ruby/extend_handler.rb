# `extend` works just like `include` except that it always
# mixes the module in in class scope,
# and that it can handle `extend self`.
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
  end
end
