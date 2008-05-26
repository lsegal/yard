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
    
    def link_object(object, otitle = nil, anchor = nil)
      object = P(current_object, object) if object.is_a?(String)
      title = h(otitle ? otitle.to_s : object.path)
      return title unless serializer

      if object.is_a?(YARD::CodeObjects::Proxy)
        log.warn "Cannot resolve link to #{object.path}. Missing file #{url_for(object, false)}."
        return title
      elsif !object.is_a?(YARD::CodeObjects::NamespaceObject)
        # If the object is not a namespace object make it the anchor.
        anchor, object = object, object.namespace
      end
      
      link = url_for(object)
      
      case anchor
      when String, Symbol
        link += "#" + urlencode(anchor)
      when YARD::CodeObjects::Base
        link += "#" + anchor_for(anchor)
      when YARD::CodeObjects::Proxy
        link += "#" + urlencode(anchor.path)
      end
      
      link.empty? ? title : "<a href='#{link}' title='#{title}'>#{title}</a>"
    end
    
    def anchor_for(object)
      if object.is_a?(YARD::CodeObjects::MethodObject)
        urlencode("#{object.name}-#{object.scope}_#{object.type}")
      else
        urlencode("#{object.name}-#{object.type}")
      end
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
    
    