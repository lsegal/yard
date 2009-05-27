module YARD::CodeObjects
  class ModuleObject < NamespaceObject
    def inheritance_tree(include_mods = false)
      return [self] unless include_mods
      [self] + mixins(:instance).map do |m|
        next m unless m.respond_to?(:inheritance_tree)
        m.inheritance_tree(true)
      end.flatten
    end
  end
end
