module YARD
  module CLI
    autoload :YardGraph,  'yard/cli/yard_graph.rb'
    autoload :Yardoc,     'yard/cli/yardoc.rb'
  end
  
  module CodeObjects
    autoload :Base,                 'yard/code_objects/base'
    autoload :CodeObjectList,       'yard/code_objects/base'
    autoload :ClassObject,          'yard/code_objects/class_object'
    autoload :ClassVariableObject,  'yard/code_objects/class_variable_object'
    autoload :ConstantObject,       'yard/code_objects/constant_object'
    autoload :MethodObject,         'yard/code_objects/method_object'
    autoload :ModuleObject,         'yard/code_objects/module_object'
    autoload :NamespaceObject,      'yard/code_objects/namespace_object'
    autoload :Proxy,                'yard/code_objects/proxy'
    autoload :ProxyMethodError,     'yard/code_objects/proxy'
    autoload :RootObject,           'yard/code_objects/root_object'
    
    autoload :BUILTIN_ALL,          'yard/code_objects/base'
    autoload :BUILTIN_CLASSES,      'yard/code_objects/base'
    autoload :BUILTIN_MODULES,      'yard/code_objects/base'
    autoload :BUILTIN_EXCEPTIONS,   'yard/code_objects/base'
    autoload :CONSTANTMATCH,        'yard/code_objects/base'
    autoload :METHODMATCH,          'yard/code_objects/base'
    autoload :METHODNAMEMATCH,      'yard/code_objects/base'
    autoload :NAMESPACEMATCH,       'yard/code_objects/base'
    autoload :NSEP,                 'yard/code_objects/base'
    autoload :NSEPQ,                'yard/code_objects/base'
    autoload :ISEP,                 'yard/code_objects/base'
    autoload :ISEPQ,                'yard/code_objects/base'
    autoload :CSEP,                 'yard/code_objects/base'
    autoload :CSEPQ,                'yard/code_objects/base'
  end
  
  module Generators
    module Helpers
      autoload :BaseHelper,             'yard/generators/helpers/base_helper'
      autoload :FilterHelper,           'yard/generators/helpers/filter_helper'
      autoload :HtmlHelper,             'yard/generators/helpers/html_helper'
      autoload :MarkupHelper,           'yard/generators/helpers/markup_helper'
      autoload :MethodHelper,           'yard/generators/helpers/method_helper'
      autoload :UMLHelper,              'yard/generators/helpers/uml_helper'
    end
    
    autoload :AttributesGenerator,      'yard/generators/attributes_generator'
    autoload :Base,                     'yard/generators/base'
    autoload :ClassGenerator,           'yard/generators/class_generator'
    autoload :ConstantsGenerator,       'yard/generators/constants_generator'
    autoload :ConstructorGenerator,     'yard/generators/constructor_generator'
    autoload :DeprecatedGenerator,      'yard/generators/deprecated_generator'
    autoload :DocstringGenerator,       'yard/generators/docstring_generator'
    autoload :FullDocGenerator,         'yard/generators/full_doc_generator'
    autoload :InheritanceGenerator,     'yard/generators/inheritance_generator'
    autoload :MethodGenerator,          'yard/generators/method_generator'
    autoload :MethodDetailsGenerator,   'yard/generators/method_details_generator'
    autoload :MethodListingGenerator,   'yard/generators/method_listing_generator'
    autoload :MethodMissingGenerator,   'yard/generators/method_missing_generator'
    autoload :MethodSignatureGenerator, 'yard/generators/method_signature_generator'
    autoload :MethodSummaryGenerator,   'yard/generators/method_summary_generator'
    autoload :MixinsGenerator,          'yard/generators/mixins_generator'
    autoload :ModuleGenerator,          'yard/generators/module_generator'
    autoload :QuickDocGenerator,        'yard/generators/quick_doc_generator'
    autoload :SourceGenerator,          'yard/generators/source_generator'
    autoload :TagsGenerator,            'yard/generators/tags_generator'
    autoload :UMLGenerator,             'yard/generators/uml_generator'
    autoload :VisibilityGroupGenerator, 'yard/generators/visibility_group_generator'
  end
  
  module Handlers
    autoload :AliasHandler,         'yard/handlers/alias_handler'
    autoload :AttributeHandler,     'yard/handlers/attribute_handler'
    autoload :Base,                 'yard/handlers/base'
    autoload :ClassHandler,         'yard/handlers/class_handler'
    autoload :ClassVariableHandler, 'yard/handlers/class_variable_handler'
    autoload :ConstantHandler,      'yard/handlers/constant_handler'
    autoload :ExceptionHandler,     'yard/handlers/exception_handler'
    autoload :MethodHandler,        'yard/handlers/method_handler'
    autoload :MixinHandler,         'yard/handlers/mixin_handler'
    autoload :ExtendHandler,        'yard/handlers/extend_handler'
    autoload :ModuleHandler,        'yard/handlers/module_handler'
    autoload :VisibilityHandler,    'yard/handlers/visibility_handler'
    autoload :UndocumentableError,  'yard/handlers/base'
    autoload :YieldHandler,         'yard/handlers/yield_handler'
  end

  module Parser
    module RubyToken
      require 'yard/parser/ruby_lex' # Too much to include manually
    end
    
    autoload :SourceParser,   'yard/parser/source_parser'
    autoload :Statement,      'yard/parser/statement'
    autoload :StatementList,  'yard/parser/statement_list'
    autoload :TokenList,      'yard/parser/token_list'
  end
  
  module Rake
    autoload :YardocTask, 'yard/rake/yardoc_task'
  end
  
  module Serializers
    autoload :Base,                 'yard/serializers/base'
    autoload :FileSystemSerializer, 'yard/serializers/file_system_serializer'
    autoload :ProcessSerializer,    'yard/serializers/process_serializer'
    autoload :StdoutSerializer,     'yard/serializers/stdout_serializer'
  end
  
  module Tags
    autoload :DefaultFactory, 'yard/tags/default_factory'
    autoload :DefaultTag,     'yard/tags/default_tag'
    autoload :Library,        'yard/tags/library'
    autoload :OptionTag,      'yard/tags/option_tag'
    autoload :RefTag,         'yard/tags/ref_tag'
    autoload :RefTagList,     'yard/tags/ref_tag_list'
    autoload :Tag,            'yard/tags/tag'
    autoload :TagFormatError, 'yard/tags/tag_format_error'
  end

  autoload :Docstring, 'yard/docstring'
  autoload :Registry,  'yard/registry'
end

# Load handlers immediately
YARD::Handlers.constants.each {|c| YARD::Handlers.const_get(c) }

# P() needs to be loaded right away
YARD::CodeObjects::Proxy
