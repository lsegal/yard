module YARD::Generators::Helpers
  module BaseHelper
    def linkify(object, title = nil)
      case object
      when YARD::CodeObjects::Base, YARD::CodeObjects::Proxy
        object.path
      when String, Symbol
        P(object).path
      else
        object
      end
    end
  end
end