module YARD::Templates::Helpers
  module BaseHelper
    attr_accessor :object, :serializer
    
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
    
    def format_object_name_list(objects)
      objects.sort_by {|o| o.name.to_s.downcase }.join(", ")
    end
    
    def format_types(list, brackets = true)
      list.empty? ? "" : (brackets ? "(#{list.join(", ")})" : list.join(", "))
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

    def overloads(method)
      if method.tags(:overload).size == 1
        method.tags(:overload)
      else
        [method]
      end
    end
    
    def signature(meth, link = true)
      type = (meth.tag(:return) && meth.tag(:return).types ? meth.tag(:return).types.first : nil) || "Object"
      type = linkify(P(object.namespace, type), type) unless link
      scope = meth.scope == :class ? "+" : "-"
      name = meth.name
      blk = format_block(meth)
      args = format_args(meth)
      extras = []
      extras_text = ''
      if rw = meth.namespace.attributes[meth.scope][meth.name]
        attname = [rw[:read] ? 'read' : nil, rw[:write] ? 'write' : nil].compact
        attname = attname.size == 1 ? attname.join('') + 'only' : nil
        extras << attname if attname
      end
      extras << meth.visibility if meth.visibility != :public
      extras_text = ' (' + extras.join(", ") + ')' unless extras.empty?
      title = "%s (%s) %s%s %s" % [scope, type, name, args, blk]
      (link ? linkify(meth, title) : title) + extras_text
    end
  end
end
