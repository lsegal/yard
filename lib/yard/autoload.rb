module YARD
  PATH_ORDER = [
    'lib/yard/autoload.rb',
    'lib/yard/code_objects/base.rb',
    'lib/yard/code_objects/namespace_object.rb',
    'lib/yard/handlers/base.rb',
    'lib/yard/generators/helpers/*.rb',
    'lib/yard/generators/base.rb',
    'lib/yard/generators/method_listing_generator.rb',
    'lib/yard/serializers/base.rb',
    'lib/**/*.rb'
  ]
  
  module CLI
    autoload :YardGraph,  'cli/yard_graph.rb'
    autoload :Yardoc,     'cli/yardoc.rb'
  end
  
  module CodeObjects
    autoload :Base,                 'code_objects/base'
    autoload :CodeObjectList,       'code_objects/base'
    autoload :ClassObject,          'code_objects/class_object'
    autoload :ClassVariableObject,  'code_objects/class_variable_object'
    autoload :ConstantObject,       'code_objects/constant_object'
    autoload :MethodObject,         'code_objects/method_object'
    autoload :ModuleObject,         'code_objects/module_object'
    autoload :NamespaceObject,      'code_objects/namespace_object'
    autoload :Proxy,                'code_objects/proxy'
    autoload :ProxyMethodError,     'code_objects/proxy'
    autoload :RootObject,           'code_objects/root_object'
  end
  
  module Generators
    module Helpers
      autoload :BaseHelper,             'generators/helpers/base_helper'
      autoload :FilterHelper,           'generators/helpers/filter_helper'
      autoload :HtmlHelper,             'generators/helpers/html_helper'
      autoload :MethodHelper,           'generators/helpers/method_helper'
    end
    
    autoload :AttributesGenerator,      'generators/attributes_generator'
    autoload :Base,                     'generators/base'
    autoload :ClassGenerator,           'generators/class_generator'
    autoload :ConstantsGenerator,       'generators/constants_generator'
    autoload :ConstructorGenerator,     'generators/constructor_generator'
    autoload :DeprecatedGenerator,      'generators/deprecated_generator'
    autoload :DocstringGenerator,       'generators/docstring_generator'
    autoload :FullDocGenerator,         'generators/full_doc_generator'
    autoload :InheritanceGenerator,     'generators/inheritance_generator'
    autoload :MethodGenerator,          'generators/method_generator'
    autoload :MethodDetailsGenerator,   'generators/method_details_generator'
    autoload :MethodListingGenerator,   'generators/method_listing_generator'
    autoload :MethodMissingGenerator,   'generators/method_missing_generator'
    autoload :MethodSignatureGenerator, 'generators/method_signature_generator'
    autoload :MethodSummaryGenerator,   'generators/method_summary_generator'
    autoload :MixinsGenerator,          'generators/mixins_generator'
    autoload :ModuleGenerator,          'generators/module_generator'
    autoload :QuickDocGenerator,        'generators/quick_doc_generator'
    autoload :SourceGenerator,          'generators/source_generator'
    autoload :TagsGenerator,            'generators/tags_generator'
    autoload :UMLGenerator,             'generators/uml_generator'
    autoload :VisibilityGroupGenerator, 'generators/visibility_group_generator'
  end
  
  module Handlers
    autoload :AliasHandler,         'handlers/alias_handler'
    autoload :AttributeHandler,     'handlers/attribute_handler'
    autoload :Base,                 'handlers/base'
    autoload :ClassHandler,         'handlers/class_handler'
    autoload :ClassVariableHandler, 'handlers/class_variable_handler'
    autoload :ConstantHandler,      'handlers/constant_handler'
    autoload :MethodHandler,        'handlers/method_handler'
    autoload :MixinHandler,         'handlers/mixin_handler'
    autoload :ModuleHandler,        'handlers/module_handler'
    autoload :VisibilityHandler,    'handlers/visibility_handler'
    autoload :UndocumentableError,  'handlers/base'
  end

  module Parser
    module RubyToken
      require File.join(YARD::ROOT, 'parser', 'ruby_lex') # Too much to include manually
    end
    
    autoload :SourceParser,   'parser/source_parser'
    autoload :Statement,      'parser/statement'
    autoload :StatementList,  'parser/statement_list'
    autoload :TokenList,      'parser/token_list'
  end
  
  module Rake
    autoload :YardocTask, 'rake/yardoc_task'
  end
  
  module Serializers
    autoload :Base,                 'serializers/base'
    autoload :FileSystemSerializer, 'serializers/file_system_serializer'
    autoload :ProcessSerializer,    'serializers/process_serializer'
    autoload :StdoutSerializer,     'serializers/stdout_serializer'
  end
  
  module Tags
    autoload :DefaultFactory, 'tags/default_factory'
    autoload :Library,        'tags/library'
    autoload :Tag,            'tags/tag'
  end

  autoload :Registry, 'registry'
end

# Load all handlers
module YARD
  module Handlers
    [ AliasHandler, AttributeHandler, ClassHandler, ClassVariableHandler,
    ConstantHandler, MethodHandler, MixinHandler, ModuleHandler, VisibilityHandler ]
  end
end

# P() needs to be loaded right away
YARD::CodeObjects::Proxy