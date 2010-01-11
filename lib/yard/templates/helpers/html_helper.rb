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

          begin
            SimpleMarkupHtml.instance_variable_set("@from_path", url_for(object))
            html = MarkupHelper::SimpleMarkup.convert(text, SimpleMarkupHtml)
          end

          html = fix_dash_dash(html)
          html = fix_typewriter(html)
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
        text.gsub(/\+(?! )([^\n\+]{1,900})(?! )\+/) do
          type_text, pre_text, no_match = $1, $`, $&
          pre_match = pre_text.scan(%r(</?(?:pre|tt|code).*?>))
          if pre_match.last.nil? || pre_match.last.include?('/')
            '<tt>' + type_text + '</tt>'
          else
            no_match
          end
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
        text.gsub(/<(\/)?(pre|code|tt)|\{(\S+?)(?:\s(.*?\S))?\}(?=[\W<]|.+<\/|$)/) do |str|
          tag = $2
          closed = $1
          if tag
            code_tags += (closed ? -1 : 1)
            next str
          end
          next str unless code_tags == 0
          
          name = $3
          title = $4 || name

          case name
          when %r{://}, /^mailto:/
            link_url(name, title, :target => '_parent')
          when /^file:(\S+?)(?:#(\S+))?$/
            link_file($1, title == name ? $1 : title, $2)
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
              "<tt>" + linkify(obj, title) + "</tt>" 
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
          type = type.gsub(/([<>])/) { h($1) }
          type = type.gsub(/([\w:]+)/) { $1 == "lt" || $1 == "gt" ? $1 : linkify($1, $1) }
          "<tt>" + type + "</tt>"
        end
        list.empty? ? "" : (brackets ? "(#{list.join(", ")})" : list.join(", "))
      end
      
      def link_file(filename, title = nil, anchor = nil)
        link_url(url_for_file(filename, anchor), title)
      end
    
      def link_object(obj, otitle = nil, anchor = nil, relative = true)
        return otitle if obj.nil?
        obj = Registry.resolve(object, obj, true, true) if obj.is_a?(String)
        if !otitle && obj.root?
          title = "Top Level Namespace"
        elsif otitle
          title = otitle.to_s
        elsif object.is_a?(CodeObjects::Base)
          title = h(object.relative_path(obj))
        else
          title = h(obj.to_s)
        end
        return title unless serializer

        return title if obj.is_a?(CodeObjects::Proxy)
      
        link = url_for(obj, anchor, relative)
        link ? link_url(link, title, :title => "#{obj.path} (#{obj.type})") : title
      end
      
      def link_url(url, title = nil, params = {})
        params = SymbolHash.new(false).update(
          :href => url,
          :title  => h(title || url)
        ).update(params)
        "<a #{tag_attrs(params)}>#{title}</a>"
      end
      
      def tag_attrs(opts = {})
        opts.sort_by {|k, v| k.to_s }.map {|k,v| "#{k}=#{v.to_s.inspect}" if v }.join(" ")
      end
    
      def anchor_for(object)
        case object
        when CodeObjects::MethodObject
          "#{object.name}-#{object.scope}_#{object.type}"
        when CodeObjects::ClassVariableObject
          "#{object.name.to_s.gsub('@@', '')}-#{object.type}"
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
          filename = 'file.' + File.basename(filename).gsub(/\.[^.]+$/, '')
        end
        link = File.relative_path(from, filename)
        link + '.html' + (anchor ? '#' + urlencode(anchor) : '')
      end
      
      def signature_types(meth, link = true)
        meth = convert_method_to_overload(meth)

        type = options[:default_return] || ""
        if meth.tag(:return) && meth.tag(:return).types
          types = meth.tags(:return).map {|t| t.types ? t.types : [] }.flatten
          first = link ? h(types.first) : format_types([types.first], false)
          if types.size == 2 && types.last == 'nil'
            type = first + '<sup>?</sup>'
          elsif types.size == 2 && types.last =~ /^(Array)?<#{Regexp.quote types.first}>$/
            type = first + '<sup>+</sup>'
          elsif types.size > 2
            type = [first, '...'].join(', ')
          elsif types == ['void'] && options[:hide_void_return]
            type = ""
          else
            type = link ? h(types.join(", ")) : format_types(types, false)
          end
        elsif !type.empty?
          type = link ? h(type) : format_types([type], false)
        end
        type = "(#{type}) " unless type.empty?
        type
      end
      
      def signature(meth, link = true, show_extras = true, full_attr_name = true)
        meth = convert_method_to_overload(meth)
        
        type = signature_types(meth, link)
        scope = meth.scope == :class ? "+" : "-"
        name = full_attr_name ? meth.name : meth.name.to_s.gsub(/=$/, '')
        blk = format_block(meth)
        args = !full_attr_name && meth.writer? ? "" : format_args(meth)
        extras = []
        extras_text = ''
        if show_extras
          if rw = meth.attr_info
            attname = [rw[:read] ? 'read' : nil, rw[:write] ? 'write' : nil].compact
            attname = attname.size == 1 ? attname.join('') + 'only' : nil
            extras << attname if attname
          end
          extras << meth.visibility if meth.visibility != :public
          extras_text = ' <span class="extras">(' + extras.join(", ") + ')</span>' unless extras.empty?
        end
        title = "%s %s<strong>%s</strong>%s %s" % [scope, type, h(name), args, blk]
        if link
          if meth.is_a?(YARD::CodeObjects::MethodObject)
            link_title = "#{h meth.name(true)} (#{meth.scope} #{meth.type})"
          else
            link_title = "#{h name} (#{meth.type})"
          end
          link_url(url_for(meth), title, :title => link_title) + extras_text
        else
          title + extras_text
        end
      end
      
      def html_syntax_highlight(source, type = :ruby)
        return "" unless source
        return source if options[:no_highlight]
        
        # handle !!!LANG prefix to send to html_syntax_highlight_LANG
        if source =~ /\A[ \t]*!!!(\w+)[ \t]*\r?\n/
          type, source = $1, $'
          source = $'
        end
        
        meth = "html_syntax_highlight_#{type}"
        respond_to?(meth) ? send(meth, source) : h(source)
      end
      
      def html_syntax_highlight_plain(source)
        h(source)
      end
      
      private
      
      def convert_method_to_overload(meth)
        # use first overload tag if it has a return type and method itself does not
        if !meth.tag(:return) && meth.tags(:overload).size == 1 && meth.tag(:overload).tag(:return)
          return meth.tag(:overload)
        end
        meth
      end
    end
  end
end
    
