module YARD::Generators::Helpers
  module BaseHelper
    def link_object(object, title = nil)
      case object
      when YARD::CodeObjects::Base, YARD::CodeObjects::Proxy
        object.path
      when String, Symbol
        P(object).path
      else
        object
      end
    end
    
    def link_url(url)
      url
    end
  end
end