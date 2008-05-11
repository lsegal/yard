class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles YARD::Parser::RubyToken::TkMODULE
  
  def process
    mod = ModuleObject.new(namespace, statement.tokens[2].text)
    mod.docstring = statement.comments
    parse_block(mod)
  end
end