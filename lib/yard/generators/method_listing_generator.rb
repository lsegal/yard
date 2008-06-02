module YARD
  module Generators
    class MethodListingGenerator < Base
      include Helpers::MethodHelper

      attr_reader :scope, :visibility
      
      def initialize(*args)
        super
        @scope = options[:scope]
        @visibility = options[:visibility]
      end
      
      protected
      
      def has_methods?(object)
        method_list.size > 0
      end
      
      def has_inherited_methods?(object)
        return false unless object.is_a?(CodeObjects::ClassObject)
        meths = object.inherited_meths
        remove_ignored_meths!(meths)
        meths.size > 0
      end

      def has_included_methods?(object)
        meths = object.included_meths
        remove_ignored_meths!(meths)
        meths.size > 0
      end
      
      def method_list
        meths = current_object.meths(meths_opts)
        remove_ignored_meths!(meths)
        meths.sort_by {|m| m.name.to_s.downcase }
      end
      
      # @yield [superclass, meths] 
      #   Yields a the list of methods pertaining to a superclass
      #   in the inheritance order.
      # 
      # @yieldparam [CodeObjects::ClassObject] superclass 
      #   The superclass the methods belong to
      # 
      # @yieldparam [Array<CodeObjects::ConstantObject>] meths
      #   The list of methods inherited from the superclass
      # 
      def inherited_meths_by_class
        all_meths = current_object.inherited_meths(:scope => scope, :visibility => visibility)
        current_object.inheritance_tree[1..-1].each do |superclass|
          next if superclass.is_a?(CodeObjects::Proxy)
          meths = superclass.meths(meths_opts).select {|c| all_meths.include?(c) }
          remove_ignored_meths!(meths)
          next if meths.empty?
          yield(superclass, meths)
        end
      end

      # @yield [mixin, meths] 
      #   Yields a the list of methods pertaining to a module
      #   in the module order.
      # 
      # @yieldparam [CodeObjects::ModuleObject] mixin 
      #   The module the methods belong to
      # 
      # @yieldparam [Array<CodeObjects::ConstantObject>] meths
      #   The list of methods included from the module
      # 
      def included_meths_by_module
        all_meths = current_object.included_meths(:scope => scope, :visibility => visibility)
        current_object.mixins.each do |mixin|
          next if mixin.is_a?(CodeObjects::Proxy)
          meths = mixin.meths(meths_opts).select {|c| all_meths.include?(c) }
          remove_ignored_meths!(meths)
          next if meths.empty?
          yield(mixin, meths)
        end
      end
      
      def ignored_meths
        { 
          :instance => [:initialize, :method_missing], 
          :class => [:new] 
        }
      end
      
      def remove_ignored_meths!(list)
        list.reject! do |o| 
          ignored_meths[o.scope].include?(o.name) || 
            o.is_alias? || (o.is_attribute? && !o.is_explicit?)
        end
      end
      
      private
      
      def meths_opts
        { 
          :included => false, :inherited => false,
          :scope => scope, :visibility => visibility 
        }
      end
    end
  end
end