# frozen_string_literal: true

# Backward compatability for gem specification lookup
# @see Gem::SourceIndex
module YARD
  module GemIndex
    module_function

    def find_all_by_name(*args)
      if defined?(Gem::Specification) && Gem::Specification.respond_to?(:find_all_by_name)
        Gem::Specification.find_all_by_name(*args)
      else
        Gem.source_index.find_name(*args)
      end
    end
  end
end
