module YARD::CodeObjects
  class NamespaceObject < Base
    attr_reader :children, :cvars, :meths, :constants, :attributes, :aliases
    
    def initialize(namespace, name, *args, &block)
      @children = CodeObjectList.new(self)
      @class_mixins = CodeObjectList.new(self)
      @instance_mixins = CodeObjectList.new(self)
      @attributes = SymbolHash[:class => SymbolHash.new, :instance => SymbolHash.new]
      @aliases = {}
      super
    end
    
    def class_attributes
      attributes[:class]
    end
    
    def instance_attributes 
      attributes[:instance]
    end
    
    def child(opts = {})
      if !opts.is_a?(Hash)
        children.find {|o| o.name == opts.to_sym }
      else
        opts = SymbolHash[opts]
        children.find do |obj| 
          opts.each do |meth, value|
            break false if !(value.is_a?(Array) ? value.include?(obj[meth]) : obj[meth] == value)
          end
        end
      end
    end
    
    def meths(opts = {})
      opts = SymbolHash[
        :visibility => [:public, :private, :protected],
        :scope => [:class, :instance],
        :included => true
      ].update(opts)
      
      opts[:visibility] = [opts[:visibility]].flatten
      opts[:scope] = [opts[:scope]].flatten

      ourmeths = children.select do |o| 
        o.is_a?(MethodObject) && 
          opts[:visibility].include?(o.visibility) &&
          opts[:scope].include?(o.scope)
      end
      
      ourmeths + (opts[:included] ? included_meths(opts) : [])
    end
    
    def included_meths(opts = {})
      Array(opts[:scope] || [:instance, :class]).map do |scope|
        mixins(scope).reverse.inject([]) do |list, mixin|
          next list if mixin.is_a?(Proxy)
          list + mixin.meths(opts.merge(:scope => :instance)).reject do |o|
            child(:name => o.name, :scope => scope) || list.find {|o2| o2.name == o.name }
          end
        end
      end.flatten
    end
    
    def constants(opts = {})
      opts = SymbolHash[:included => true].update(opts)
      consts = children.select {|o| o.is_a? ConstantObject }
      consts + (opts[:included] ? included_constants : [])
    end
    
    def included_constants
      mixins(:instance).reverse.inject([]) do |list, mixin|
        if mixin.respond_to? :constants
          list += mixin.constants.reject do |o| 
            child(:name => o.name) || list.find {|o2| o2.name == o.name }
          end
        else
          list
        end
      end
    end
    
    def cvars 
      children.select {|o| o.is_a? ClassVariableObject }
    end

    def mixins(*scopes)
      raise ArgumentError, "Scopes must be :instance, :class, or both" if scopes.empty?
      return @class_mixins if scopes == [:class]
      return @instance_mixins if scopes == [:instance]

      unless (scopes - [:instance, :class]).empty?
        raise ArgumentError, "Scopes must be :instance, :class, or both"
      end

      return @class_mixins | @instance_mixins
    end
  end
end
