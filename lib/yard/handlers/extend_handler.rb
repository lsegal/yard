# `extend` works just like `include` except that it always
# mixes the module in in class scope,
# and that it can handle `extend self`.
class YARD::Handlers::ExtendHandler < YARD::Handlers::MixinHandler
  handles /\Aextend(\s|\()/

  def scope; :class; end

  private

  def process_mixin(mixin)
    super unless mixin =~ /\Aself/
    namespace.mixins(:class) << namespace
  end
end
