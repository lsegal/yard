class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles YARD::Parser::RubyToken::TkMODULE
  
  def process
    modname = statement.tokens.to_s[/^module\s+([^ ;]+)/, 1]
    mod = ModuleObject.new(namespace, modname)
    mod.docstring = statement.comments
    parse_block(mod)
  end
end