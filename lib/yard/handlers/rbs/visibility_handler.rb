# frozen_string_literal: true

# Handles 'private' and 'public' calls.
class YARD::Handlers::RBS::VisibilityHandler < YARD::Handlers::RBS::Base
  handles ::RBS::AST::Members::Public
  handles ::RBS::AST::Members::Private

  process do
    case statement
    when ::RBS::AST::Members::Public
      self.visibility = :public
    when ::RBS::AST::Members::Private
      self.visibility = :private
    end
  end
end
