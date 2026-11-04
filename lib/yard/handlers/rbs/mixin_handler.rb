# frozen_string_literal: true
# Handles RBS include, extend, and prepend declarations.
class YARD::Handlers::RBS::MixinHandler < YARD::Handlers::RBS::Base
  handles :include, :extend, :prepend

  process do
    case mixin = Proxy.new(namespace, statement.mixin_name)
    when ConstantObject # If a constant is included, use its value as the real object
      mixin = Proxy.new(namespace, mixin.value || statement.mixin_name, :module)
    else
      mixin = Proxy.new(namespace, statement.mixin_name, :module)
    end

    case statement.type
    when :include
      mixins = namespace.mixins(:instance)
      mixins << mixin unless mixins.include?(mixin)
    when :extend
      mixins = namespace.mixins(:class)
      mixins << mixin unless mixins.include?(mixin)
    when :prepend
      mixins = namespace.mixins(:instance)
      mixins.unshift(mixin) unless mixins.include?(mixin)
    end
  end
end
