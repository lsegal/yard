module YARD
  module Generators
    class ConstantsGenerator < Base
      before_section :constants, :has_constants?
      before_section :inherited, :has_inherited_constants?
      
      def sections_for(object) 
        if object.is_a?(CodeObjects::ClassObject)
          [:header, [:constants, :inherited]] 
        elsif object.is_a?(CodeObjects::ModuleObject)
          [:header, [:constants]]
        end
      end

      protected
      
      def has_constants?(object)
        object.constants(false).size > 0
      end
      
      def has_inherited_constants?(object)
        object.inherited_constants.size > 0
      end
        
      # @yield [superclass, constlist] 
      #   Yields a the list of methods pertaining to a superclass
      #   in the inheritance order.
      # 
      # @yieldparam [CodeObjects::ClassObject] superclass 
      #   The superclass the constants belong to
      # @yieldparam [Array<CodeObjects::ConstantObject>] consts
      #   The list of constants inherited from the superclass
      # 
      def inherited_constants_by_class
        all_consts = current_object.inherited_constants
        current_object.inheritance_tree[1..-1].each do |superclass|
          consts = superclass.constants(false).select {|c| all_consts.include?(c) }
          next if consts.empty?
          yield(superclass, consts)
        end
      end
    end
  end
end