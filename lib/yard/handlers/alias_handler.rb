class YARD::Handlers::AliasHandler < YARD::Handlers::Base
  handles /\Aalias_method/
  
  def process
    toks = statement.tokens.squeeze
    begin
      new_meth, old_meth = toks[2..-1].to_s.split(',')
      new_meth, old_meth = eval(new_meth), eval(old_meth)
    rescue SyntaxError, NameError
      raise YARD::Handlers::UndocumentableError, "alias_method"
    end
    
    old_obj = namespace.meths(:scope => scope).find {|o| o.name == old_meth }
    new_obj = MethodObject.new(namespace, new_meth, scope) do |o|
      o.visibility = visibility
      o.scope = scope
      o.line = statement.tokens.first.line_no
      o.file = parser.file
      o.docstring = statement.comments

      if old_obj
        o.signature = old_obj.signature
        o.source = old_obj.source
      else
        o.signature = "def #{new_meth}"
      end
    end
    
    namespace.aliases[old_meth] = new_obj
  end
end