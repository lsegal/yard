class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles TkMODULE
  
  def process
    modname = statement.tokens.to_s[/^module\s+(#{NAMESPACEMATCH})/, 1]
    mod = register ModuleObject.new(namespace, modname)
    parse_block(:namespace => mod)
  end
end