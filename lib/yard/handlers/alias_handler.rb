class YARD::Handlers::AliasHandler < YARD::Handlers::Base
  handles /\Aalias_method/
  
  def process
    begin
      statement.tokens.to_s[2..-1].to_s =~ /\s*(\S+)\s*,\s*(\S+)/
      new_meth, old_meth = eval($1), eval($2)
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
      o.dynamic = true if owner != namespace

      if old_obj
        o.signature = old_obj.signature
        o.source = old_obj.source
      else
        o.signature = "def #{new_meth}"
      end
    end
    
    namespace.aliases[new_obj] = old_meth
  end
end