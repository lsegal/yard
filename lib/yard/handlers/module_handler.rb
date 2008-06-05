class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles TkMODULE
  
  def process
    modname = statement.tokens.to_s[/^module\s+(#{NAMESPACEMATCH})/, 1]
    register mod = ModuleObject.new(namespace, modname)
    parse_block(:namespace => mod)
  end
end