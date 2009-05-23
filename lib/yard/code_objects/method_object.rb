module YARD::CodeObjects
  class MethodObject < Base
    attr_accessor :visibility, :scope, :explicit, :parameters
    
    def initialize(namespace, name, scope = :instance) 
      self.visibility = :public
      self.scope = scope
      self.parameters = []

      super
    end
    
    def scope=(v) 
      reregister = @scope ? true : false
      YARD::Registry.delete(self) if reregister
      @scope = v.to_sym 
      YARD::Registry.register(self) if reregister
    end
    
    def visibility=(v) @visibility = v.to_sym end
      
    def is_attribute?
      namespace.attributes[scope].has_key? name.to_s.gsub(/=$/, '')
    end
      
    def is_alias?
      namespace.aliases.has_key? self
    end
    
    def is_explicit?
      explicit ? true : false
    end
    
    def aliases
      list = []
      namespace.aliases.each do |o, aname| 
        list << o if aname == name && o.scope == scope 
      end
      list
    end
    
    def path
      if !namespace || namespace.path == "" 
        sep + super
      else
        super
      end
    end
    
    def name(prefix = false)
      ((prefix ? sep : "") + super().to_s).to_sym
    end
    
    protected
    
    def sep
      if scope == :class
        namespace && namespace != YARD::Registry.root ? CSEP : NSEP
      else
        ISEP
      end
    end
  end
end
