module YARD
  module CodeObjects
    # Represents the root namespace object (the invisible Ruby module that
    # holds all top level modules, class and other objects).
    class RootObject < ModuleObject
      def path; "" end
      def inspect; "#<yardoc root>" end
      def root?; true end
    end
  end
end