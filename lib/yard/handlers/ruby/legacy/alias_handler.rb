class YARD::Handlers::Ruby::Legacy::AliasHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /\Aalias(_method)?(\s|\()/
  
  def process
    if TkALIAS === statement.tokens.first 
      tokens = statement.tokens[2..-1].to_s.split(/\s+/)
      names = [tokens[0], tokens[1]].map {|t| t.gsub(/^:/, '') }
    else
      names = tokval_list(statement.tokens[2..-1], :attr)
    end
    raise YARD::Parser::UndocumentableError, statement.tokens.first.text if names.size != 2
    
    new_meth, old_meth = names[0].to_sym, names[1].to_sym
    old_obj = namespace.child(:name => old_meth, :scope => scope)
    new_obj = register MethodObject.new(namespace, new_meth, scope) do |o|
      o.visibility = visibility
      o.scope = scope
      o.add_file(parser.file, statement.tokens.first.line_no)
      o.docstring = statement.comments

      if old_obj
        o.signature = old_obj.signature
        o.source = old_obj.source
      else
        o.signature = "def #{new_meth}" # this is all we know.
      end
    end
    
    namespace.aliases[new_obj] = old_meth
  end
end