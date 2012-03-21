require 'ostruct'

module YARD
  module Tags
    class Directive
      attr_accessor :tag
      attr_accessor :expanded_text

      def initialize(tag, parser)
        self.tag = tag
        self.parser = parser
        self.expanded_text = nil
      end

      def object; parser.object end
      def handler; parser.handler end

      def call; raise NotImplementedError end
      def after_parse; end

      protected

      attr_accessor :parser
    end

    class EndGroupDirective < Directive
      def call
        return unless handler
        handler.extra_state.group = nil
      end
    end

    class GroupDirective < Directive
      def call
        return unless handler
        handler.extra_state.group = tag.text
      end
    end

    class MacroDirective < Directive
      def call
        raise TagFormatError if tag.name.nil? && tag.text.to_s.empty?
        unless macro_data = find_or_create
          warn
          return
        end

        self.expanded_text = expand(macro_data)
      end

      private

      def new?
        (tag.types && tag.types.include?('new')) ||
          (tag.text && !tag.text.strip.empty?)
      end

      def attach?
         class_method? || # always attach to class methods
          (tag.types && tag.types.include?('attach'))
      end

      def class_method?
        object && object.is_a?(CodeObjects::MethodObject) &&
          object.scope == :class
      end

      def expand(macro_data)
        return if attach? && class_method?
        return if new? && (!handler || handler.statement.source.empty?)
        call_params = []
        caller_method = nil
        full_source = ''
        if handler
          call_params = handler.call_params
          caller_method = handler.caller_method
          full_source = handler.statement.source
        end
        all_params = ([caller_method] + call_params).compact
        CodeObjects::MacroObject.expand(macro_data, all_params, full_source)
      end

      def find_or_create
        if new? || attach?
          if handler && attach?
            obj = object ? object :
              P("#{handler.namespace}.#{handler.caller_method}")
          else
            obj = nil
          end
          if tag.name.nil? || tag.name.empty? # anonymous macro
            return tag.text || ""
          else
            macro = CodeObjects::MacroObject.create(tag.name, tag.text, obj)
          end
        else
          macro = CodeObjects::MacroObject.find(tag.name)
        end

        macro ? macro.macro_data : nil
      end

      def warn
        if object && handler
          log.warn "Invalid/missing macro name for " +
            "#{object.path} (#{handler.parser.file}:#{handler.statement.line})"
        end
      end
    end

    class MethodDirective < Directive
      SCOPE_MATCH = /\A\s*self\s*\.\s*/

      def call; end

      def after_parse
        return unless handler
        use_indented_text
        create_object
      end

      protected

      def method_name
        sig = sanitized_tag_signature
        if sig && sig =~ /^#{CodeObjects::METHODNAMEMATCH}(\s|\(|$)/
          sig[/\A\s*([^\(; \t]+)/, 1]
        else
          handler.call_params.first
        end
      end

      def method_signature
        "def #{sanitized_tag_signature || method_name}"
      end

      def sanitized_tag_signature
        if tag.name && tag.name =~ SCOPE_MATCH
          parser.state.scope = :class
          $'
        else
          tag.name
        end
      end

      def use_indented_text
        return if tag.text.empty?
        handler = parser.handler
        object = parser.object
        self.parser = DocstringParser.new(parser.library)
        parser.parse(tag.text, object, handler)
      end

      def create_object
        name = method_name
        scope = parser.state.scope || handler.scope
        visibility = parser.state.visibility || handler.visibility
        ns = CodeObjects::NamespaceObject === object ? object : handler.namespace
        obj = CodeObjects::MethodObject.new(ns, name, scope)
        handler.register_file_info(obj)
        handler.register_source(obj)
        handler.register_group(obj)
        obj.dynamic = true
        obj.signature = method_signature
        obj.visibility = visibility
        obj.docstring = Docstring.new!(parser.text, parser.tags, obj,
          parser.raw_text)
        obj
      end
    end

    class AttributeDirective < MethodDirective
      def after_parse
        return unless handler
        use_indented_text
        create_attribute_data(create_object)
      end

      protected

      def method_name
        name = sanitized_tag_signature || handler.call_params.first
        name += '=' unless readable?
        name
      end

      def method_signature
        if readable?
          "def #{method_name}"
        else
          "def #{method_name}(value)"
        end
      end

      private

      def create_attribute_data(object)
        return unless object
        clean_name = object.name.to_s.sub(/=$/, '')
        attrs = object.namespace.attributes[object.scope]
        attrs[clean_name] ||= SymbolHash[:read => nil, :write => nil]
        if readable?
          attrs[clean_name][:read] = object
        end
        if writable?
          if object.name.to_s[-1,1] == '='
            writer = object
            writer.parameters = [['value', nil]]
          else
            writer = CodeObjects::MethodObject.new(object.namespace,
              object.name.to_s + '=', object.scope)
            writer.signature = "def #{object.name}=(value)"
            writer.visibility = object.visibility
            writer.dynamic = object.dynamic
            writer.source = object.source
            writer.group = object.group
            writer.parameters = [['value', nil]]
            handler.register_file_info(writer)
          end
          attrs[clean_name][:write] = writer
        end
      end

      def writable?
        !tag.types || tag.types.join.include?('w')
      end

      def readable?
        !tag.types || tag.types.join =~ /(?!w)r/
      end
    end

    class ScopeDirective < Directive
      def call
        if %w(class instance).include?(tag.text)
          if object
            object.scope = tag.text.to_sym
          else
            parser.state.scope = tag.text.to_sym
          end
        end
      end
    end

    class VisibilityDirective < Directive
      def call
        if %w(public protected private).include?(tag.text)
          if object
            object.visibility = tag.text.to_sym
          else
            parser.state.visibility = tag.text.to_sym
          end
        end
      end
    end
  end
end