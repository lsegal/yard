class YARD::Handlers::AliasHandler < YARD::Handlers::Base
  handles /\Aalias_method/
  
  def process
    names = tokval_list(statement.tokens[2..-1], :attr)
    raise YARD::Handlers::UndocumentableError, "alias_method" if names.size != 2
    
    new_meth, old_meth = names[0].to_sym, names[1].to_sym
    old_obj = namespace.child(:name => old_meth, :scope => scope)
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
        o.signature = "def #{new_meth}" # this is all we know.
      end
    end
    
    namespace.aliases[new_obj] = old_meth
    
    new_obj # return for registration
  end
end