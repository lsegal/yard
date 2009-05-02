# `extend` works just like `include` except that it always
# mixes the module in in class scope.
class YARD::Handlers::ExtendHandler < YARD::Handlers::MixinHandler
  handles /\Aextend(\s|\()/

  def scope; :class; end
end
