require 'cgi'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module YARD
  module Generators::Helpers
    module HtmlHelper
      SimpleMarkup = SM::SimpleMarkup.new
      SimpleMarkupHtml = SM::ToHtml.new
    
      def h(text)
        CGI.escapeHTML(text.to_s)
      end
    
      def urlencode(text)
        CGI.escape(text.to_s)
      end

      def htmlify(text)
        resolve_links SimpleMarkup.convert(text, SimpleMarkupHtml)
      end

      def resolve_links(text)
        text.gsub(/(\s)\{(\S+)\}(?=(?:[\s\.,:!;\?][^<>]*)?<\/(?!pre))/) do 
          title = $2
          obj = P(current_object, title)
          if obj.is_a?(CodeObjects::Proxy)
            log.warn "In documentation for #{current_object.path}: Cannot resolve link to #{obj.path} from text:"
            log.warn '...' + text[/(.{0,20}\{#{title}\}.{0,20})/, 1].gsub(/\n/,"\n\t") + '...'
          end
          
          " <tt>" + linkify(obj, title) + "</tt>" 
        end
      end

      def format_object_name_list(objects)
        objects.sort_by {|o| o.name.to_s.downcase }.map do |o| 
          "<span class='name'>" + linkify(o, o.name) + "</span>" 
        end.join(", ")
      end
      
      # Formats a list of types from a tag.
      # 
      # @param [Array<String>, FalseClass] typelist
      #   the list of types to be formatted. 
      # 
      # @param [Boolean] brackets omits the surrounding 
      #   brackets if +brackets+ is set to +false+.
      # 
      # @return [String] the list of types formatted
      #   as [Type1, Type2, ...] with the types linked
      #   to their respective descriptions.
      # 
      def format_types(typelist, brackets = true)
        list = typelist.map do |type| 
          "<tt>" + type.gsub(/(^|[<>])\s*([^<>#]+)\s*(?=[<>]|$)/) {|m| h($1) + linkify($2, $2) } + "</tt>"
        end
        list.empty? ? "" : (brackets ? "[#{list.join(", ")}]" : list.join(", "))
      end
    
      def link_object(object, otitle = nil, anchor = nil)
        object = P(current_object, object) if object.is_a?(String)
        title = h(otitle ? otitle.to_s : object.path)
        return title unless serializer

        return title if object.is_a?(CodeObjects::Proxy)
      
        link = url_for(object, anchor)
        link ? "<a href='#{link}' title='#{title}'>#{title}</a>" : title
      end
    
      def anchor_for(object)
        urlencode case object
        when CodeObjects::MethodObject
          "#{object.name}-#{object.scope}_#{object.type}"
        when CodeObjects::Base
          "#{object.name}-#{object.type}"
        when CodeObjects::Proxy
          object.path
        else
          object.to_s
        end
      end
    
      def url_for(object, anchor = nil, relative = true)
        link = nil
        return link unless serializer
        
        if object.is_a?(CodeObjects::Base) && !object.is_a?(CodeObjects::NamespaceObject)
          # If the object is not a namespace object make it the anchor.
          anchor, object = object, object.namespace
        end
        
        objpath = serializer.serialized_path(object)
        return link unless objpath
      
        if relative
          fromobj = current_object
          if current_object.is_a?(CodeObjects::Base) && 
              !current_object.is_a?(CodeObjects::NamespaceObject)
            fromobj = fromobj.namespace
          end

          from  = serializer.serialized_path(fromobj)
          link  = File.relative_path(from, objpath)
        else
          link = objpath
        end
      
        link + (anchor ? '#' + anchor_for(anchor) : '')
      end
    end
  end
end
    
    