module YARD::CodeObjects
  class NamespaceObject < Base
    attr_reader :children, :cvars, :meths, :constants, :mixins, :attributes, :aliases
    
    def initialize(namespace, name, *args, &block)
      @children = CodeObjectList.new(self)
      @mixins = CodeObjectList.new(self)
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
            break false if obj[meth] != value
          end
        end
      end
    end
    
    def meths(opts = {})
      opts = SymbolHash[
        :visibility => [:public, :private, :protected],
        :scope => [:class, :instance],
        :mixins => true
      ].update(opts)
      
      opts[:visibility] = [opts[:visibility]].flatten
      opts[:scope] = [opts[:scope]].flatten

      ourmeths = children.select do |o| 
        o.is_a?(MethodObject) && 
          opts[:visibility].include?(o.visibility) &&
          opts[:scope].include?(o.scope)
      end
      
      ourmeths + (opts[:mixins] ? mixin_meths(opts) : [])
    end
    
    def mixin_meths(opts = {})
      mixins.reverse.inject([]) do |list, mixin|
        if mixin.is_a?(Proxy)
          list
        else
          list += mixin.meths(opts).reject do |o| 
            child(:name => o.name, :scope => o.scope) || 
              list.find {|o2| o2.name == o.name && o2.scope == o.scope }
          end
        end
      end
    end
    
    def constants
      children.select {|o| o.is_a? ConstantObject }
    end
    
    def cvars 
      children.select {|o| o.is_a? ClassVariableObject }
    end
  end
end