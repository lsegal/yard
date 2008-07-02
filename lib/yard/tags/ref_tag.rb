module YARD
  module Tags
    class RefTag
      attr_accessor :owner, :tag_name, :name
      
      def initialize(tag_name, owner, name = nil)
        @owner = CodeObjects::Proxy === owner ? owner : P(owner)
        @tag_name = tag_name.to_s
        @name = name
      end
      
      def tags
        if owner.is_a?(CodeObjects::Base)
          o = owner.tags(tag_name)
          name ? o.select {|x| x.name.to_s == name.to_s } : o
        else
          []
        end
      end
    end
  end
end