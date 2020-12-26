# frozen_string_literal: true

# Handles the 'include' / 'prepend' / 'extend' statement to mixin a module in the instance scope
class YARD::Handlers::RBS::MixinHandler < YARD::Handlers::RBS::Base
  handles ::RBS::AST::Members::Mixin

  process do
    receiver = P(namespace, statement.name.to_s)

    case statement
    when ::RBS::AST::Members::Include
      namespace.mixins(:instance).unshift(receiver)
    when ::RBS::AST::Members::Prepend
      namespace.mixins(:instance).push(receiver)
    when ::RBS::AST::Members::Extend
      namespace.mixins(:class).unshift(receiver)
    end
  end
end
