module YARD::CodeObjects
  class NamespaceObject < Base
    attr_reader :children, :cvars, :meths, :constants, :mixins, :attributes
    
    def initialize(namespace, name, *args, &block)
      @children = CodeObjectList.new(self)
      @mixins = CodeObjectList.new(self)
      @attributes = SymbolHash.new
      super
    end
    
    def child(name)
      children.find {|o| o.name == name.to_sym }
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
      
      if opts[:mixins]
        methnames = ourmeths.map {|o| o.name }
        mixinmeths = mixins.inject([]) do |list, mixin|
          next if mixin.is_a?(Proxy)
          list += mixin.meths(opts).reject do |o| 
            methnames.include? o.name 
          end
        end
        mixinmeths + ourmeths
      else
        ourmeths
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