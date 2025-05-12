# frozen_string_literal: true
# Handles 'extend' call to include modules into the class scope of another
# @see MixinHandler
class YARD::Handlers::Ruby::ExtendHandler < YARD::Handlers::Ruby::MixinHandler
  handles method_call(:extend)
  namespace_only

  def scope; :class end

  private

  def process_mixin(mixin)
    if mixin == s(:var_ref, s(:kw, "self"))
      raise UndocumentableError, "extend(self) statement on class" if namespace.is_a?(ClassObject)
      namespace.mixins(scope) << namespace
    else
      super
    end
  end
end
