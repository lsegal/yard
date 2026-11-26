# frozen_string_literal: true
# Handles RBS visibility sections: a bare `public` or `private` line sets
# the visibility of the instance members declared after it.
class YARD::Handlers::RBS::VisibilityHandler < YARD::Handlers::RBS::Base
  handles :visibility
  namespace_only

  process do
    self.visibility = statement.name.to_sym
    globals.visibility_origin = :keyword
  end
end
