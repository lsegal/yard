module YARD::Templates::Helpers
  module BaseHelper
    attr_accessor :object, :serializer
    
    def run_verifier(list)
      return list unless options[:verifier]
      list.reject {|item| options[:verifier].call(item).is_a?(FalseClass) }
    end
    
    # This is used a lot by the HtmlHelper and there should
    # be some helper to "clean up" text for whatever, this is it.
    def h(text)
      text
    end
    
    def linkify(*args) 
      # The :// character sequence exists in no valid object path but just about every URL scheme.
      if args.first.is_a?(String) && args.first.include?("://")
        link_url(*args)
      else
        link_object(*args)
      end
    end

    def link_object(object, title = nil)
      return title if title
      
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
    
    def format_types(list, brackets = true)
      list.nil? || list.empty? ? "" : (brackets ? "(#{list.join(", ")})" : list.join(", "))
    end

    def format_object_type(object)
      case object
      when YARD::CodeObjects::ClassObject
        object.is_exception? ? "Exception" : "Class"
      else
        object.type.to_s.capitalize
      end
    end
    
    def format_object_title(object)
      case object
      when YARD::CodeObjects::RootObject
        "Top Level Namespace"
      else
        format_object_type(object) + ": " + object.path
      end
    end
    
    def format_source(value)
      sp = value.split("\n").last[/^(\s+)/, 1]
      num = sp ? sp.size : 0
      value.gsub(/^\s{#{num}}/, '')
    end
  end
end
