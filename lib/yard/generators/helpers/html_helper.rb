require 'cgi'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module YARD::Generators::Helpers
  module HtmlHelper
    SimpleMarkup = SM::SimpleMarkup.new
    SimpleMarkupHtml = SM::ToHtml.new
    
    def h(text)
      CGI.escapeHTML(text)
    end
    
    def urlencode(text)
      #CGI.escape(text)
      text
    end

    def htmlify(text)
      resolve_links SimpleMarkup.convert(text, SimpleMarkupHtml)
    end

    def resolve_links(text)
      text.gsub(/\{(\S+)\}/) do 
        "<tt>" + linkify(P(current_object, $1)) + "</tt>" 
      end
    end
    
    def linkify(*args) 
      # The :// character sequence exists in no valid object path but just about every URL scheme.
      if args.first.is_a?(String) && args.first.include?("://")
        link_url(*args)
      else
        link_object(*args)
      end
    end
    
    def link_object(object, title = nil, anchor = nil)
      title = title.to_s if title
      object = P(current_object, object) if object.is_a?(String)
      return title || object.path unless serializer

      if object.is_a?(YARD::CodeObjects::Proxy)
        log.warn "Cannot resolve link to #{object.path}. Missing file #{url_for(object, false)}."
        return object.path 
      end
      
      title = h(title || object.path)
      link = url_for(object)
      
      case anchor
      when String, Symbol
        link += "#" + urlencode(anchor)
      when YARD::CodeObjects::Base
        link += "#" + urlencode(anchor.name.to_s + "-" + anchor.type.to_s)
      when YARD::CodeObjects::Proxy
        link += "#" + urlencode(anchor.path)
      end
      
      link.empty? ? title : "<a href='#{link}' title='#{title}'>#{title}</a>"
    end
    
    def url_for(object, relative = true)
      return '' if serializer.nil?
      objpath = serializer.serialized_path(object)
      return '' if objpath.nil?
      
      if relative
        from = serializer.serialized_path(current_object)
        urlencode File.relative_path(from, objpath)
      else
        urlencode(objpath)
      end
    end
  end
end
    
    