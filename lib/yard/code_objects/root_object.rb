module YARD
  module CodeObjects
    class RootObject < ModuleObject
      def path; "" end
      def inspect; "#<yardoc root>" end
    end
  end
end