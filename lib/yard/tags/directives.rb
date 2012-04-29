require 'ostruct'

module YARD
  module Tags
    # The base directive class. Subclass this class to create a custom
    # directive, registering it with {Library.define_directive}. Directive
    # classes are executed via the {#call} method, which perform all directive
    # processing on the object.
    #
    # If processing occurs within a handler, the {#handler} attribute is
    # available to access more information about parsing context and state.
    # Handlers are only available when parsing from {Parser::SourceParser},
    # not when parsing directly from {DocstringParser}. If the docstring is
    # attached to an object declaration, {#object} will be set and available
    # to modify the generated code object directly. Note that both of these
    # attributes may be nil, and directives should test their existence
    # before attempting to use them.
    #
    # @abstract Subclasses should implement {#call}.
    # @see Library.define_directive
    class Directive
      # @return [Tag] the meta-data tag containing data input to the directive
      attr_accessor :tag

      # Set this field to replace the directive definition inside of a docstring
      # with arbitrary text. For instance, the {MacroDirective} uses this field
      # to expand its macro data in place of the call to a +@!macro+.
      #
      # @return [String] the text to expand in the original docstring in place
      #   of this directive definition.
      # @return [nil] if no expansion should take place for this directive
      attr_accessor :expanded_text

      # @return [DocstringParser] the parser that is parsing all tag 
      #   information out of the docstring
      attr_accessor :parser

      # @!attribute [r] object
      # @return [CodeObjects::Base, nil] the object the parent docstring is
      #   attached to. May be nil.
      def object; parser.object end

      # @!attribute [r] handler
      # @return [Handlers::Base, nil] the handler object the docstring parser
      #   might be attached to. May be nil. Only available when parsing
      #   through {Parser::SourceParser}.
      def handler; parser.handler end

      # @!endgroup

      # @param [Tag] the meta-data tag containing all input to the docstring
      # @param [DocstringParser] the docstring parser object
      def initialize(tag, parser)
        self.tag = tag
        self.parser = parser
        self.expanded_text = nil
      end

      # @!group Parser callbacks

      # Called when processing the directive. Subclasses should implement
      # this method to perform all functionality of the directive.
      #
      # @abstract implement this method to perform all data processing for
      #   the directive.
      # @return [void]
      def call; raise NotImplementedError end

      # Called after parsing all directives and tags in the docstring. Used
      # to perform any cleanup after all directives perform their main task.
      # @return [void]
      def after_parse; end

      protected :parser
    end

    # Ends a group listing definition. Group definition automatically end
    # when class or module blocks are closed, and defining a new group overrides
    # the last group definition, but occasionally you need to end the current
    # group to return to the default listing. Use {tag:!group} to begin a
    # group listing.
    #
    # @example
    #   class Controller
    #     # @!group Callbacks
    #
    #     def before_filter; end
    #     def after_filter; end
    #
    #     # @!endgroup
    #
    #     def index; end
    #   end
    # @see tag:!group
    class EndGroupDirective < Directive
      def call
        return unless handler
        handler.extra_state.group = nil
      end
    end

    # Defines a group listing. All methods (and attributes) seen after this
    # directive are placed into a group with the given description as the
    # group name. The group listing is used by templates to organize methods
    # and attributes into respective logical groups. To end a group listing
    # use {tag:!endgroup}.
    #
    # @note A group definition only applies to the scope it is defined in.
    #   If a new class or module is opened after the directive, this directive
    #   will not apply to methods in that class or module.
    # @example
    #   # @!group Callbacks
    #
    #   def before_filter; end
    #   def after_filter; end
    # @see tag:!endgroup
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

      def anonymous?
        tag.name.nil? || tag.name.empty?
      end

      def expand(macro_data)
        return if attach? && class_method?
        return if !anonymous? && new? &&
          (!handler || handler.statement.source.empty?)
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
          if anonymous? # anonymous macro
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
        handler.register_visibility(obj, visibility)
        handler.register_group(obj)
        obj.signature = method_signature
        obj.docstring = Docstring.new!(parser.text, parser.tags, obj,
          parser.raw_text)
        handler.register_module_function(obj)
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

    # Parses a block of code as if it were present in the source file at that
    # location. This directive is useful if a class has dynamic meta-programmed
    # behaviour that cannot be recognized by YARD.
    #
    # You can specify the language of the code block using the types 
    # specification list. By default, the code language is "ruby".
    #
    # @example Documenting dynamic module inclusion
    #   class User
    #     # includes "UserMixin" and extends "UserMixin::ClassMethods"
    #     # using the UserMixin.included callback.
    #     # @!parse include UserMixin
    #     # @!parse extend UserMixin::ClassMethods
    #   end
    # @example Declaring a method as an attribute
    #   # This should really be an attribute
    #   # @!parse attr_reader :foo
    #   def object; @parent.object end
    # @example Parsing C code
    #   # @!parse [c]
    #   #   void Init_Foo() {
    #   #     rb_define_method(rb_cFoo, "method", method, 0);
    #   #   }
    class ParseDirective < Directive
      def call
        lang = tag.types ? tag.types.first.to_sym :
          (handler ? handler.parser.parser_type : :ruby)
        if handler && lang == handler.parser.parser_type
          pclass = Parser::SourceParser.parser_types[handler.parser.parser_type]
          pobj = pclass.new(tag.text, handler.parser.file)
          pobj.parse
          handler.parser.process(pobj.enumerator)
        else # initialize a new parse chain
          src_parser = Parser::SourceParser.new(lang, handler ? handler.globals : nil)
          src_parser.file = handler.parser.file if handler
          src_parser.parse(StringIO.new(tag.text))
        end
      end
    end

    class ScopeDirective < Directive
      def call
        if %w(class instance module).include?(tag.text)
          if object.is_a?(CodeObjects::MethodObject)
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
          if object.is_a?(CodeObjects::Base)
            object.visibility = tag.text.to_sym
          else
            parser.state.visibility = tag.text.to_sym
          end
        end
      end
    end
  end
end