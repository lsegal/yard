module YARD::Generators::Helpers
  module BaseHelper
    def linkify(object, title = nil)
      object.path
    end
  end
end