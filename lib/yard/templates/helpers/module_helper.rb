module YARD
  module Templates
    module Helpers
      module ModuleHelper
        def prune_method_listing(list, hide_attributes = true)
          list = run_verifier(list)
          list = list.reject {|o| !options[:visibilities].include? o.visibility } if options[:visibilities]
          list = list.reject(&:is_alias?)
          list = list.reject(&:is_attribute?) if hide_attributes
          list
        end
      end
    end
  end
end