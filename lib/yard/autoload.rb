module YARD
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
    autoload :Base,                     'generators/base'
    autoload :DeprecatedGenerator,      'generators/deprecated_generator'
    autoload :DocstringGenerator,       'generators/docstring_generator'
    autoload :MethodSignatureGenerator, 'generators/method_signature_generator'
    autoload :QuickDocGenerator,        'generators/quick_doc_generator'
    autoload :SourceGenerator,          'generators/source_generator'
    autoload :TagsGenerator,            'generators/tags_generator'
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
      require File.join(YARD::ROOT, 'parser/ruby_lex') # Too much to include manually
    end
    
    autoload :SourceParser,   'parser/source_parser'
    autoload :Statement,      'parser/statement'
    autoload :StatementList,  'parser/statement_list'
    autoload :TokenList,      'parser/token_list'
  end
  
  module Serializers
    autoload :Base,                 'serializers/base'
    autoload :FileSystemSerializer, 'serializers/file_system_serializer'
    autoload :StdoutSerializer,     'serializers/stdout_serializer'
  end
  
  module Tags
    autoload :Library,  'tags/library'
    autoload :Tag,      'tags/tag'
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

autoload :P, 'code_objects/proxy'