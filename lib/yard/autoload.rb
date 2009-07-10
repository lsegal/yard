def __p(*path) File.join(YARD::ROOT, 'yard', *path) end

module YARD
  module CLI
    autoload :YardGraph,  __p('cli/yard_graph')
    autoload :Yardoc,     __p('cli/yardoc')
  end
  
  module CodeObjects
    autoload :Base,                 __p('code_objects/base')
    autoload :CodeObjectList,       __p('code_objects/base')
    autoload :ClassObject,          __p('code_objects/class_object')
    autoload :ClassVariableObject,  __p('code_objects/class_variable_object')
    autoload :ConstantObject,       __p('code_objects/constant_object')
    autoload :ExtendedMethodObject, __p('code_objects/extended_method_object')
    autoload :MethodObject,         __p('code_objects/method_object')
    autoload :ModuleObject,         __p('code_objects/module_object')
    autoload :NamespaceObject,      __p('code_objects/namespace_object')
    autoload :Proxy,                __p('code_objects/proxy')
    autoload :ProxyMethodError,     __p('code_objects/proxy')
    autoload :RootObject,           __p('code_objects/root_object')
    
    autoload :BUILTIN_ALL,          __p('code_objects/base')
    autoload :BUILTIN_CLASSES,      __p('code_objects/base')
    autoload :BUILTIN_MODULES,      __p('code_objects/base')
    autoload :BUILTIN_EXCEPTIONS,   __p('code_objects/base')
    autoload :CONSTANTMATCH,        __p('code_objects/base')
    autoload :METHODMATCH,          __p('code_objects/base')
    autoload :METHODNAMEMATCH,      __p('code_objects/base')
    autoload :NAMESPACEMATCH,       __p('code_objects/base')
    autoload :NSEP,                 __p('code_objects/base')
    autoload :NSEPQ,                __p('code_objects/base')
    autoload :ISEP,                 __p('code_objects/base')
    autoload :ISEPQ,                __p('code_objects/base')
    autoload :CSEP,                 __p('code_objects/base')
    autoload :CSEPQ,                __p('code_objects/base')
  end
  
  module Generators
    module Helpers
      autoload :BaseHelper,                 __p('generators/helpers/base_helper')
      autoload :FilterHelper,               __p('generators/helpers/filter_helper')
      autoload :HtmlHelper,                 __p('generators/helpers/html_helper')
      autoload :HtmlSyntaxHighlightHelper,  __p('generators/helpers/html_syntax_highlight_helper')
      autoload :MarkupHelper,               __p('generators/helpers/markup_helper')
      autoload :MethodHelper,               __p('generators/helpers/method_helper')
      autoload :UMLHelper,                  __p('generators/helpers/uml_helper')
    end
    
    autoload :AttributesGenerator,      __p('generators/attributes_generator')
    autoload :Base,                     __p('generators/base')
    autoload :ClassGenerator,           __p('generators/class_generator')
    autoload :ConstantsGenerator,       __p('generators/constants_generator')
    autoload :ConstructorGenerator,     __p('generators/constructor_generator')
    autoload :DeprecatedGenerator,      __p('generators/deprecated_generator')
    autoload :DocstringGenerator,       __p('generators/docstring_generator')
    autoload :FullDocGenerator,         __p('generators/full_doc_generator')
    autoload :InheritanceGenerator,     __p('generators/inheritance_generator')
    autoload :MethodGenerator,          __p('generators/method_generator')
    autoload :MethodDetailsGenerator,   __p('generators/method_details_generator')
    autoload :MethodListingGenerator,   __p('generators/method_listing_generator')
    autoload :MethodMissingGenerator,   __p('generators/method_missing_generator')
    autoload :MethodSignatureGenerator, __p('generators/method_signature_generator')
    autoload :MethodSummaryGenerator,   __p('generators/method_summary_generator')
    autoload :MixinsGenerator,          __p('generators/mixins_generator')
    autoload :ModuleGenerator,          __p('generators/module_generator')
    autoload :QuickDocGenerator,        __p('generators/quick_doc_generator')
    autoload :RootGenerator,            __p('generators/root_generator')
    autoload :SourceGenerator,          __p('generators/source_generator')
    autoload :TagsGenerator,            __p('generators/tags_generator')
    autoload :UMLGenerator,             __p('generators/uml_generator')
    autoload :VisibilityGroupGenerator, __p('generators/visibility_group_generator')
    autoload :OverloadsGenerator,       __p('generators/overloads_generator')
  end
  
  module Handlers
    module Ruby
      module Legacy
        autoload :Base,                 __p('handlers/ruby/legacy/base')

        autoload :AliasHandler,         __p('handlers/ruby/legacy/alias_handler')
        autoload :AttributeHandler,     __p('handlers/ruby/legacy/attribute_handler')
        autoload :ClassHandler,         __p('handlers/ruby/legacy/class_handler')
        autoload :ClassVariableHandler, __p('handlers/ruby/legacy/class_variable_handler')
        autoload :ConstantHandler,      __p('handlers/ruby/legacy/constant_handler')
        autoload :ExceptionHandler,     __p('handlers/ruby/legacy/exception_handler')
        autoload :ExtendHandler,        __p('handlers/ruby/legacy/extend_handler')
        autoload :MethodHandler,        __p('handlers/ruby/legacy/method_handler')
        autoload :MixinHandler,         __p('handlers/ruby/legacy/mixin_handler')
        autoload :ModuleHandler,        __p('handlers/ruby/legacy/module_handler')
        autoload :VisibilityHandler,    __p('handlers/ruby/legacy/visibility_handler')
        autoload :YieldHandler,         __p('handlers/ruby/legacy/yield_handler')
      end

      autoload :Base,                   __p('handlers/ruby/base')

      autoload :AliasHandler,           __p('handlers/ruby/alias_handler')
      autoload :AttributeHandler,       __p('handlers/ruby/attribute_handler')
      autoload :ClassHandler,           __p('handlers/ruby/class_handler')
      autoload :ClassConditionHandler,  __p('handlers/ruby/class_condition_handler')
      autoload :ClassVariableHandler,   __p('handlers/ruby/class_variable_handler')
      autoload :ConstantHandler,        __p('handlers/ruby/constant_handler')
      autoload :ExceptionHandler,       __p('handlers/ruby/exception_handler')
      autoload :ExtendHandler,          __p('handlers/ruby/extend_handler')
      autoload :MethodHandler,          __p('handlers/ruby/method_handler')
      autoload :MethodConditionHandler, __p('handlers/ruby/method_condition_handler')
      autoload :MixinHandler,           __p('handlers/ruby/mixin_handler')
      autoload :ModuleHandler,          __p('handlers/ruby/module_handler')
      autoload :VisibilityHandler,      __p('handlers/ruby/visibility_handler')
      autoload :YieldHandler,           __p('handlers/ruby/yield_handler')
    end

    autoload :Base,                     __p('handlers/base')
    autoload :Processor,                __p('handlers/processor')
  end

  module Parser
    module Ruby
      module Legacy
        autoload :RubyToken,      __p('parser/ruby/legacy/ruby_lex')
        autoload :Statement,      __p('parser/ruby/legacy/statement')
        autoload :StatementList,  __p('parser/ruby/legacy/statement_list')
        autoload :TokenList,      __p('parser/ruby/legacy/token_list')
      end

      autoload :AstNode,           __p('parser/ruby/ast_node')
      autoload :ParserSyntaxError, __p('parser/ruby/ruby_parser')
      autoload :RubyParser,        __p('parser/ruby/ruby_parser')
    end

    autoload :SourceParser,        __p('parser/source_parser')
    autoload :UndocumentableError, __p('parser/source_parser')
  end
  
  module Rake
    autoload :YardocTask, __p('rake/yardoc_task')
  end
  
  module Serializers
    autoload :Base,                 __p('serializers/base')
    autoload :FileSystemSerializer, __p('serializers/file_system_serializer')
    autoload :ProcessSerializer,    __p('serializers/process_serializer')
    autoload :StdoutSerializer,     __p('serializers/stdout_serializer')
  end
  
  module Tags
    autoload :DefaultFactory, __p('tags/default_factory')
    autoload :DefaultTag,     __p('tags/default_tag')
    autoload :Library,        __p('tags/library')
    autoload :OptionTag,      __p('tags/option_tag')
    autoload :OverloadTag,    __p('tags/overload_tag')
    autoload :RefTag,         __p('tags/ref_tag')
    autoload :RefTagList,     __p('tags/ref_tag_list')
    autoload :Tag,            __p('tags/tag')
    autoload :TagFormatError, __p('tags/tag_format_error')
  end

  autoload :Docstring, __p('docstring')
  autoload :Logger,    __p('logging')
  autoload :Registry,  __p('registry')
end

autoload :Tadpole, __p('templating')

undef __p
