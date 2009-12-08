# Parts of this source were borrowed from `rdoc/parser/c.rb`
# RDoc's license is packaged along with Ruby.


module YARD
  module Parser
    class CParser
      def initialize(source, file = '(stdin)')
        @file = file
        @namespaces = {}
        @content = clean_source(source)
      end
      
      def parse
        parse_modules
        parse_classes
        parse_methods
        parse_includes
      end
      
      protected
      
      def ensure_loaded!(object, max_retries = 1)
        return if object == Registry.root
        if RUBY_PLATFORM =~ /java/ || defined?(::Rubinius)
          unless $NO_CONTINUATION_WARNING
            $NO_CONTINUATION_WARNING = true
            log.warn "JRuby/Rubinius do not implement Kernel#callcc and cannot " +
              "load files in order. You must specify the correct order manually."
          end
          raise NamespaceMissingError, object
        end
        
        retries = 0
        context = callcc {|c| c }
        retries += 1 
        
        if object.is_a?(CodeObjects::Proxy)
          if retries <= max_retries
            log.debug "Missing object #{object} in file `#{@file}', moving it to the back of the line."
            raise Parser::LoadOrderError, context
          end
        end
        object
      end

      def handle_module(var_name, mod_name, in_module = nil)
        namespace = @namespaces[in_module] || (in_module ? P(in_module.gsub(/^rb_[mc]/, '')) : :root)
        ensure_loaded!(namespace)
        obj = CodeObjects::ModuleObject.new(namespace, mod_name)
        obj.add_file(@file)
        find_namespace_docstring(obj)      
        @namespaces[var_name] = obj
      end

      def handle_class(var_name, class_name, parent, in_module = nil)
        namespace = @namespaces[in_module] || (in_module ? P(in_module.gsub(/^rb_[mc]/, '')) : :root)
        ensure_loaded!(namespace)
        obj = CodeObjects::ClassObject.new(namespace, class_name)
        obj.superclass = @namespaces[parent] || parent.gsub(/^rb_[mc]/, '')
        obj.add_file(@file)
        find_namespace_docstring(obj)      
        @namespaces[var_name] = obj
      end
      
      # @todo Handle +source_file+
      def handle_method(scope, var_name, name, func_name, source_file = nil)
        case scope
        when "singleton_method", "module_function"; scope = :class
        else; scope = :instance
        end
        
        namespace = @namespaces[var_name] || P(var_name.gsub(/^rb_[mc]/, ''))
        ensure_loaded!(namespace)
        obj = CodeObjects::MethodObject.new(namespace, name, scope)
        obj.add_file(@file)
        obj.parameters = []
        obj.docstring.add_tag(YARD::Tags::Tag.new(:return, '', 'Boolean')) if name =~ /\?$/
        find_method_body(obj, func_name)
      end
      
      def handle_constants(type, var_name, const_name, definition)
        namespace = @namespaces[var_name]
        obj = CodeObjects::ConstantObject.new(namespace, const_name)
        comment = find_constant_docstring(type, const_name)

        # In the case of rb_define_const, the definition and comment are in
        # "/* definition: comment */" form.  The literal ':' and '\' characters
        # can be escaped with a backslash.
        if type.downcase == 'const'
          elements = comment.split(':')
          new_definition = elements[0..-2].join(':')
          if new_definition.empty? then # Default to literal C definition
            new_definition = definition
          else
            new_definition.gsub!("\:", ":")
            new_definition.gsub!("\\", '\\')
          end
          new_definition.sub!(/\A(\s+)/, '')
          comment = $1.nil? ? elements.last : "#{$1}#{elements.last.lstrip}"
        end

        obj.docstring = comment
      end
      
      def find_namespace_docstring(object)
        comment = nil
        if @content =~ %r{((?>/\*.*?\*/\s+))
                       (static\s+)?void\s+Init_#{object.name}\s*(?:_\(\s*)?\(\s*(?:void\s*)\)}xmi then
          comment = $1
        elsif @content =~ %r{Document-(?:class|module):\s#{object.path}\s*?(?:<\s+[:,\w]+)?\n((?>.*?\*/))}m
          comment = $1
        else
          if @content =~ /rb_define_(class|module)/m then
            comments = []
            @content.split(/(\/\*.*?\*\/)\s*?\n/m).each_with_index do |chunk, index|
              comments[index] = chunk
              if chunk =~ /rb_define_(class|module).*?"(#{object.name})"/m then
                comment = comments[index-1]
                break
              end
            end
          end
        end
        object.docstring = parse_comments(comment) if comment
      end
      
      def find_constant_docstring(type, const_name)
        comments = if @content =~ %r{((?>^\s*/\*.*?\*/\s+))
                       rb_define_#{type}\((?:\s*(\w+),)?\s*"#{const_name}"\s*,.*?\)\s*;}xmi
          $1
        elsif @content =~ %r{Document-(?:const|global|variable):\s#{const_name}\s*?\n((?>.*?\*/))}m
          $1
        else
          ''
        end
        parse_comments(comments)
      end
      
      def find_method_body(object, func_name, content = @content)
        case content
        when %r"((?>/\*.*?\*/\s*))(?:(?:static|SWIGINTERN)\s+)?(?:intern\s+)?VALUE\s+#{func_name}
                \s*(\([^)]*\))([^;]|$)"xm
          comment, params = $1, $2
          body_text = $&

          remove_private_comments(comment) if comment

          # see if we can find the whole body

          re = Regexp.escape(body_text) + '[^(]*^\{.*?^\}'
          body_text = $& if /#{re}/m =~ content

          # The comment block may have been overridden with a 'Document-method'
          # block. This happens in the interpreter when multiple methods are
          # vectored through to the same C method but those methods are logically
          # distinct (for example Kernel.hash and Kernel.object_id share the same
          # implementation

          # override_comment = find_override_comment(object)
          # comment = override_comment if override_comment

          object.docstring = parse_comments(comment) if comment
          object.source = body_text
        when %r{((?>/\*.*?\*/\s*))^\s*\#\s*define\s+#{func_name}\s+(\w+)}m
          comment = $1
          find_method_body(object, $2, content)
        else
          # No body, but might still have an override comment
          # comment = find_override_comment(object)
          comment = nil
          object.docstring = parse_comments(comment) if comment
        end
      end
      
      def parse_comments(comments)
        spaces = nil
        comments = remove_private_comments(comments)
        comments = comments.split(/\r?\n/).map do |line|
          line.gsub!(/^\s*\/?\*\/?/, '')
          line.gsub!(/\*\/\s*$/, '')
          if line =~ /^\s*$/
            next if spaces.nil?
            next ""
          end
          spaces = (line[/^(\s+)/, 1] || "").size if spaces.nil?
          line.gsub(/^\s{0,#{spaces}}/, '').rstrip
        end.compact
        
        comments = parse_callseq(comments)
        comments.join("\n")
      end
      
      def parse_callseq(comments)
        return comments unless comments[0] =~ /^call-seq:\s*(\S.+)/
        if $1
          comments[0] = " #{$1}"
        else
          comments.shift
        end
        overloads = []
        while comments.first =~ /^\s+(\S.+)/ || comments.first =~ /^\s*$/
          line = comments.shift.strip
          next if line.empty?
          line.sub!(/^\w+[\.#]/, '')
          signature, types = *line.split(/ [-=]> /)
          types = (types||"").split(/,| or /).map {|t| t.strip }.map do |t|
            {"obj" => "Object",
             "arr" => "Array",
             "str" => "String",
             "enum" => "Enumerator"}[t]
          end.compact
          if signature.sub!(/\[?\s*(\{(?:\s*\|(.+?)\|)?.*\})\s*\]?\s*$/, '') && $1
            blk, blkparams = $1, $2
          else
            blk, blkparams = nil, nil
          end
          if signature =~ /^\w+\s+\S/
            signature = signature.split(/\s+/)
            signature = "#{signature[1]}#{signature[2] ? '(' + signature[2..-1].join(' ') + ')' : ''}"
          elsif signature =~ /^\w+\[(.+?)\]\s*(=)?/
            signature = "[]#{$2}(#{$1})"
          end
          signature = signature.rstrip
          overloads << "@overload #{signature}"
          overloads << "  @yield [#{blkparams}]" if blk
          overloads << "  @return [#{types.join(', ')}]" unless types.empty?
        end
        
        comments + [""] + overloads
      end
      
      def parse_modules
        @content.scan(/(\w+)\s* = \s*rb_define_module\s*
            \(\s*"(\w+)"\s*\)/mx) do |var_name, class_name|
          handle_module(var_name, class_name)
        end

        @content.scan(/(\w+)\s* = \s*rb_define_module_under\s*
                  \(
                     \s*(\w+),
                     \s*"(\w+)"
                  \s*\)/mx) do |var_name, in_module, class_name|
          handle_module(var_name, class_name, in_module)
        end
      end
      
      def parse_classes
        # The '.' lets us handle SWIG-generated files
        @content.scan(/([\w\.]+)\s* = \s*rb_define_class\s*
                  \(
                     \s*"(\w+)",
                     \s*(\w+)\s*
                  \)/mx) do |var_name, class_name, parent|
          handle_class(var_name, class_name, parent)
        end

        @content.scan(/([\w\.]+)\s* = \s*rb_define_class_under\s*
                  \(
                     \s*(\w+),
                     \s*"(\w+)",
                     \s*([\w\*\s\(\)\.\->]+)\s*  # for SWIG
                  \s*\)/mx) do |var_name, in_module, class_name, parent|
          handle_class(var_name, class_name, parent, in_module)
        end
      end
      
      def parse_methods
        @content.scan(%r{rb_define_
                       (
                          singleton_method |
                          method           |
                          module_function  |
                          private_method
                       )
                       \s*\(\s*([\w\.]+),
                         \s*"([^"]+)",
                         \s*(?:RUBY_METHOD_FUNC\(|VALUEFUNC\()?(\w+)\)?,
                         \s*(-?\w+)\s*\)
                       (?:;\s*/[*/]\s+in\s+(\w+?\.[cy]))?
                     }xm) do |type, var_name, name, func_name, param_count, source_file|

          # Ignore top-object and weird struct.c dynamic stuff
          next if var_name == "ruby_top_self"
          next if var_name == "nstr"
          next if var_name == "envtbl"

          var_name = "rb_cObject" if var_name == "rb_mKernel"
          handle_method(type, var_name, name, func_name, source_file)
        end

        @content.scan(%r{rb_define_global_function\s*\(
                                 \s*"([^"]+)",
                                 \s*(?:RUBY_METHOD_FUNC\(|VALUEFUNC\()?(\w+)\)?,
                                 \s*(-?\w+)\s*\)
                    (?:;\s*/[*/]\s+in\s+(\w+?\.[cy]))?
                    }xm) do |name, func_name, param_count, source_file|
          handle_method("method", "rb_mKernel", name, func_name, source_file)
        end
      end
      
      def parse_includes
        @content.scan(/rb_include_module\s*\(\s*(\w+?),\s*(\w+?)\s*\)/) do |klass, mod|
          if klass = @namespaces[klass]
            mod = @namespaces[mod] || P(mod.gsub(/^rb_[mc]/, ''))
            klass.mixins(:instance) << mod
          end
        end
      end
      
      def parse_constants
        @content.scan(%r{\Wrb_define_
                       (
                          variable |
                          readonly_variable |
                          const |
                          global_const |
                        )
                   \s*\(
                     (?:\s*(\w+),)?
                     \s*"(\w+)",
                     \s*(.*?)\s*\)\s*;
                     }xm) do |type, var_name, const_name, definition|
          var_name = "rb_cObject" if !var_name or var_name == "rb_mKernel"
          handle_constants(type, var_name, const_name, definition)
        end
      end
      
      private
      
      def clean_source(source)
        source = handle_ifdefs_in(source)
        source = handle_tab_width(source)
        source = remove_commented_out_lines(source)
        source
      end
      
      def handle_ifdefs_in(body)
        body.gsub(/^#ifdef HAVE_PROTOTYPES.*?#else.*?\n(.*?)#endif.*?\n/m, '\1')
      end
      
      def handle_tab_width(body)
        if /\t/ =~ body
          tab_width = 4
          body.split(/\n/).map do |line|
            1 while line.gsub!(/\t+/) { ' ' * (tab_width*$&.length - $`.length % tab_width)}  && $~ #`
            line
          end .join("\n")
        else
          body
        end
      end
        
      def remove_commented_out_lines(body)
        body.gsub(%r{//.*rb_define_}, '//')
      end
      
      def remove_private_comments(comment)
         comment = comment.gsub(/\/?\*--\n(.*?)\/?\*\+\+/m, '')
         comment = comment.sub(/\/?\*--\n.*/m, '')
         comment
      end
    end
  end
end