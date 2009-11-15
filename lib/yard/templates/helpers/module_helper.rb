module YARD
  module Templates
    module Helpers
      module ModuleHelper
        def prune_method_listing(list, hide_attributes = true)
          list = run_verifier(list)
          list = list.reject {|o| !options[:visibilities].include? o.visibility } if options[:visibilities]
          list = list.reject {|o| o.is_alias? unless CodeObjects::Proxy === o.namespace }
          list = list.reject {|o| o.is_attribute? unless CodeObjects::Proxy === o.namespace } if hide_attributes
          list
        end
      end
    end
  end
end