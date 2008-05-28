module YARD
  module Generators
    class FullDocGenerator < Base
      before_generate :is_namespace?
      
      def sections_for(object) 
        case object
        when CodeObjects::ClassObject
          [ClassGenerator]
        when CodeObjects::ModuleObject
          [ModuleGenerator]
        end
      end
    end
  end
end