class YARD::CodeObjectHandler
  class << self
    def subclasses
      @@subclasses || []
    end
  
    def inherited(subclass)
      @@subclasses ||= []
      @@subclasses << subclass
    end
  
    def handles(token)
      @handler = token
    end
  
    def handles?(tokens)
      case @handler
      when String
        tokens.first.text == @handler
      when Regexp
        tokens.to_s =~ @handler
      else
        @handler <= tokens.first.class
      end
    end
  end
  
  attr_reader :parser, :statement
  
  def initialize(source_parser, stmt)
    @parser = source_parser
    @statement = stmt
  end
  
  def process
  end
  
  protected
    def current_visibility
      current_namespace.attributes[:visibility]
    end

    def current_visibility=(value)
      current_namespace.attributes[:visibility] = value
    end
    
    def current_scope
      current_namespace.attributes[:scope]
    end
    
    def current_scope=(value)
      current_namespace.attributes[:scope] = value
    end
    
    def object
      current_namespace.object
    end
    
    def attributes
      current_namespace.attributes
    end
  
    def current_namespace
      parser.current_namespace
    end
  
    def current_namespace=(value)
      parser.current_namespace = value
    end
  
    def enter_namespace(name, *args, &block)
      namespace = parser.current_namespace
      if name.is_a? YARD::CodeObject
        self.current_namespace = YARD::NameStruct.new(name)
        #object.add_child(name)
        yield(name)
      else
        object.add_child(name, *args) do |obj| 
          self.current_namespace = YARD::NameStruct.new(obj)
          obj.attach_source(statement.tokens.to_s, parser.file, statement.tokens.first.line_no)
          obj.attach_docstring(statement.comments) 
          yield(obj)
        end
      end
      self.current_namespace = namespace
    end
    
    def move_to_namespace(namespace)
      # If the class extends over a namespace, go to the proper object
      if namespace.include? "::"
        path = namespace.split("::") 
        name = path.pop
        path = path.join("::")
        full_namespace = [object.path, path].compact.join("::").gsub(/^::/, '')
        current_namespace.object = YARD::Namespace.find_or_create_namespace(full_namespace)
        namespace = name
      end
      namespace
    end
    
    def parse_block
      parser.parse(statement.block) if statement.block
    end
end