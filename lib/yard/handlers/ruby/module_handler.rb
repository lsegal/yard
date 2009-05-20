class YARD::Handlers::Ruby::ModuleHandler < YARD::Handlers::Ruby::Base
  handles :module
  
  def process
    modname = statement[0].source
    mod = register ModuleObject.new(namespace, modname)
    parse_block(statement[1], :namespace => mod)
  end
end