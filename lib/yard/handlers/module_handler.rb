class YARD::Handlers::ModuleHandler < YARD::Handlers::Base
  handles TkMODULE
  
  def process
    modname = statement.tokens.to_s[/^module\s+([^ ;]+)/, 1]
    mod = ModuleObject.new(namespace, modname) do |o|
      o.docstring = statement.comments
      #o.source = statement
      o.line = statement.tokens.first.line_no
      o.file = parser.file
      o.dynamic = true if owner != namespace
    end
    parse_block(:namespace => mod)
  end
end