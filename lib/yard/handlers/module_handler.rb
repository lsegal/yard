class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles YARD::Parser::RubyToken::TkMODULE
  
  def process
    modname = statement.tokens.to_s[/^module\s+([^ ;]+)/, 1]
    mod = ModuleObject.new(namespace, modname) do |o|
      o.docstring = statement.comments
      o.source = statement
      o.file = parser.file
    end
    parse_block(mod)
  end
end