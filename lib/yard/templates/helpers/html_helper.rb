require 'cgi'

module YARD
  module Templates::Helpers
    module HtmlHelper
      include MarkupHelper
      include HtmlSyntaxHighlightHelper
      
      SimpleMarkupHtml = RDoc::Markup::ToHtml.new rescue SM::ToHtml.new
    
      # Escapes HTML entities
      # 
      # @param [String] text the text to escape
      # @return [String] the HTML with escaped entities
      def h(text)
        CGI.escapeHTML(text.to_s)
      end
    
      # Escapes a URL
      # 
      # @param [String] text the URL
      # @return [String] the escaped URL
      def urlencode(text)
        CGI.escape(text.to_s)
      end

      # Turns text into HTML using +markup+ style formatting.
      # 
      # @param [String] text the text to format
      # @param [Symbol] markup examples are +:markdown+, +:textile+, +:rdoc+.
      #   To add a custom markup type, see {MarkupHelper}
      # @return [String] the HTML
      def htmlify(text, markup = options[:markup])
        return "" unless text
        return text unless markup
        load_markup_provider(markup)

        # TODO: other libraries might be more complex
        case markup
        when :markdown
          html = markup_class(markup).new(text).to_html
        when :textile
          doc = markup_class(markup).new(text)
          doc.hard_breaks = false if doc.respond_to?(:hard_breaks=)
          html = doc.to_html
        when :rdoc
          html = fix_typewriter(text)

          begin
            SimpleMarkupHtml.instance_variable_set("@from_path", url_for(object))
            html = MarkupHelper::SimpleMarkup.convert(html, SimpleMarkupHtml)
          end

          html = fix_dash_dash(html)
        end

        html = resolve_links(html)
        html = html.gsub(/<pre>(?:\s*<code>)?(.+?)(?:<\/code>\s*)?<\/pre>/m) do
          str = $1
          str = html_syntax_highlight(CGI.unescapeHTML(str)) unless options[:no_highlight]
          %Q{<pre class="code">#{str}</pre>}
        end
        html
      end
      
      # @return [String] HTMLified text as a single line (paragraphs removed)
      def htmlify_line(*args)
        htmlify(*args).gsub(/<\/?p>/, '')
      end
      
      # Fixes RDoc behaviour with ++ only supporting alphanumeric text.
      # 
      # @todo Refactor into own SimpleMarkup subclass
      def fix_typewriter(text)
        text.gsub(/\+(?! )([^\+]{1,900})(?! )\+/) do
          '<tt>' + $1.gsub(/(.)/, "\\1\004") + '</tt>'
        end
      end
      
      # Don't allow -- to turn into &#8212; element. The chances of this being
      # some --option is far more likely than the typographical meaning.
      # 
      # @todo Refactor into own SimpleMarkup subclass
      def fix_dash_dash(text)
        text.gsub(/&#8212;(?=\S)/, '--')
      end

      # Resolves any text in the form of +{Name}+ to the object specified by
      # Name. Also supports link titles in the form +{Name title}+.
      # 
      # @example Linking to an instance method
      #   resolve_links("{MyClass#method}") # => "<a href='...'>MyClass#method</a>"
      # @example Linking to a class with a title
      #   resolve_links("{A::B::C the C class}") # => "<a href='...'>the c class</a>"
      # @param [String] text the text to resolve links in
      # @return [String] HTML with linkified references
      def resolve_links(text)
        code_tags = 0
        text.gsub(/<(\/)?(pre|code|tt)|(\s|>|^)\{(\S+?)(?:\s(.*?\S))?\}(?=[\W<]|.+<\/|$)/) do |str|
          tag = $2
          closed = $1
          if tag
            code_tags += (closed ? -1 : 1)
            next str
          end
          next str unless code_tags == 0
          
          sp, name = $3, $4
          title = $5 || name

          case name
          when %r{://}, /^mailto:/
            sp + link_url(name, title, :target => '_parent')
          when /^file:(\S+?)(?:#(\S+))?$/
            sp + link_file($1, title == name ? $1 : title, $2)
          else
            if object.is_a?(String)
              obj = name
            else
              obj = Registry.resolve(object, name, true, true)
              if obj.is_a?(CodeObjects::Proxy)
                match = text[/(.{0,20}\{.*?#{Regexp.quote name}.*?\}.{0,20})/, 1]
                log.warn "In file `#{object.file}':#{object.line}: Cannot resolve link to #{obj.path} from text" + (match ? ":" : ".")
                log.warn '...' + match.gsub(/\n/,"\n\t") + '...' if match
              end
              "#{sp}<tt>" + linkify(obj, title) + "</tt>" 
            end
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
        list.empty? ? "" : (brackets ? "(#{list.join(", ")})" : list.join(", "))
      end
      
      def link_file(filename, title = nil, anchor = nil)
        link_url(url_for_file(filename, anchor), title)
      end
    
      def link_object(obj, otitle = nil, anchor = nil, relative = true)
        return otitle if obj.nil?
        obj = Registry.resolve(object, obj, true, true) if obj.is_a?(String)
        title = otitle ? otitle.to_s : h(obj.path)
        title = "Top Level Namespace" if title == "" && obj == Registry.root
        return title unless serializer

        return title if obj.is_a?(CodeObjects::Proxy)
      
        link = url_for(obj, anchor, relative)
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
        case object
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
    
      def url_for(obj, anchor = nil, relative = true)
        link = nil
        return link unless serializer
        
        if obj.is_a?(CodeObjects::Base) && !obj.is_a?(CodeObjects::NamespaceObject)
          # If the obj is not a namespace obj make it the anchor.
          anchor, obj = obj, obj.namespace
        end
        
        objpath = serializer.serialized_path(obj)
        return link unless objpath
      
        if relative
          fromobj = object
          if object.is_a?(CodeObjects::Base) && 
              !object.is_a?(CodeObjects::NamespaceObject)
            fromobj = fromobj.namespace
          end

          from = serializer.serialized_path(fromobj)
          link = File.relative_path(from, objpath)
        else
          link = objpath
        end
      
        link + (anchor ? '#' + urlencode(anchor_for(anchor)) : '')
      end
      
      def url_for_file(filename, anchor = nil)
        fromobj = object
        if CodeObjects::Base === fromobj && !fromobj.is_a?(CodeObjects::NamespaceObject)
          fromobj = fromobj.namespace
        end
        from = serializer.serialized_path(fromobj)
        if filename == options[:readme]
          filename = 'index'
        else
          filename = 'file.' + File.basename(filename).gsub(/\..+$/, '')
        end
        link = File.relative_path(from, filename)
        link + '.html' + (anchor ? '#' + urlencode(anchor) : '')
      end
      
      def signature(meth, link = true, show_extras = true)
        if link
          type = (meth.tag(:return) && meth.tag(:return).types ? meth.tag(:return).types.first : nil) || "Object"
          type = h(type)
        else
          arr = meth.tag(:return) ? [(meth.tag(:return).types || []).first].compact : []
          arr << "Object" if arr.empty?
          type = format_types(arr, false)
        end
        
        scope = meth.scope == :class ? "+" : "-"
        name = meth.name
        blk = format_block(meth)
        args = format_args(meth)
        extras = []
        extras_text = ''
        if show_extras
          if rw = meth.namespace.attributes[meth.scope][meth.name]
            attname = [rw[:read] ? 'read' : nil, rw[:write] ? 'write' : nil].compact
            attname = attname.size == 1 ? attname.join('') + 'only' : nil
            extras << attname if attname
          end
          extras << meth.visibility if meth.visibility != :public
          extras_text = ' <span class="extras">(' + extras.join(", ") + ')</span>' unless extras.empty?
        end
        title = "%s (%s) <strong>%s</strong>%s %s" % [scope, type, name, args, blk]
        (link ? linkify(meth, title) : title) + extras_text
      end
    end
  end
end
    
