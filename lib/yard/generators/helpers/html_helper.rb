require 'cgi'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

require 'rubygems'
begin require 'bluecloth'; rescue LoadError; end
begin require 'redcloth'; rescue LoadError; end

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

      def htmlify(text, markup = options[:markup])
        case markup
        when :markdown
          begin
            html = BlueCloth.new(text).to_html
          rescue NameError
            STDERR.puts "Missing BlueCloth gem for Markdown formatting. Install it with `gem install BlueCloth`"
            exit
          end
        when :textile
          begin
            html = RedCloth.new(text).to_html
          rescue NameError
            STDERR.puts "Missing RedCloth gem for Textile formatting. Install it with `gem install RedCloth`"
            exit
          end
        else # this is :rdoc
          html = SimpleMarkup.convert(text, SimpleMarkupHtml)
          html = fix_dash_dash(html)
          html = fix_typewriter(html)
        end

        html = resolve_links(html)
        html = html.gsub(/<pre>(?:\s*<code>)?(.+?)(?:<\/code>\s*)?<\/pre>/m) { '<pre class="code">' + html_syntax_highlight(CGI.unescapeHTML($1)) + '</pre>' }
        html
      end
      
      # @todo Refactor into own SimpleMarkup subclass
      def fix_typewriter(text)
        text.gsub(/\+(?! )([^\+]{1,900})(?! )\+/, '<tt>\1</tt>')
      end
      
      # Don't allow -- to turn into &#8212; element. The chances of this being
      # some --option is far more likely than the typographical meaning.
      # 
      # @todo Refactor into own SimpleMarkup subclass
      def fix_dash_dash(text)
        text.gsub(/&#8212;(?=\S)/, '--')
      end

      def resolve_links(text)
        text.gsub(/(\s|>|^)\{(\S+?)(?:\s(.*?\S))?\}(?=[\W<]|.+<\/(?!pre)|$)/) do 
          sp, name = $1, $2
          title = $3 || $2

          if name.include?("://")
            sp + link_url(name, title, :target => '_parent')
          else
            obj = P(current_object, name)
            if obj.is_a?(CodeObjects::Proxy)
              match = text[/(.{0,20}\{.*?#{Regexp.quote name}.*?\}.{0,20})/, 1]
              log.warn "In file `#{current_object.file}':#{current_object.line}: Cannot resolve link to #{obj.path} from text" + (match ? ":" : ".")
              log.warn '...' + match.gsub(/\n/,"\n\t") + '...' if match
            end
          
            "#{sp}<tt>" + linkify(obj, title) + "</tt>" 
          end
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
        return unless typelist.is_a?(Array)
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
        link ? link_url(link, title) : title
      end
      
      def link_url(url, title = nil, params = {})
        params = SymbolHash.new(false).update(
          :href => url,
          :title  => title || url
        ).update(params)
        "<a #{tag_attrs(params)}>#{title}</a>"
      end
      
      def tag_attrs(opts = {})
        opts.map {|k,v| "#{k}=#{v.to_s.inspect}" if v }.join(" ")
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

      def html_syntax_highlight(source)
        tokenlist = Parser::TokenList.new(source)
        tokenlist.map do |s| 
          prettyclass = s.class.class_name.sub(/^Tk/, '').downcase
          prettysuper = s.class.superclass.class_name.sub(/^Tk/, '').downcase

          case s
          when Parser::RubyToken::TkWhitespace, Parser::RubyToken::TkUnknownChar
            h s.text
          when Parser::RubyToken::TkId
            prettyval = h(s.text)
            "<span class='#{prettyval} #{prettyclass} #{prettysuper}'>#{prettyval}</span>"
          else
            "<span class='#{prettyclass} #{prettysuper}'>#{h s.text}</span>"
          end
        end.join
      end
    end
  end
end
    
    