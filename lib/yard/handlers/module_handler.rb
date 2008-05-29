class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles TkMODULE
  
  def process
    modname = statement.tokens.to_s[/^module\s+([^ ;]+)/, 1]
    mod = ModuleObject.new(namespace, modname)
    parse_block(:namespace => mod)
    mod # return for registration
  end
end