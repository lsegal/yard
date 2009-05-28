class YARD::Handlers::Ruby::AliasHandler < YARD::Handlers::Ruby::Base
  handles :alias, method_call(:alias_method)
  
  def process
    names = []
    if statement.type == :alias
      names = statement.map {|o| o.jump(:ident, :op, :kw, :const).first }
    elsif statement.call?
      statement.parameters(false).each do |obj|
        case obj.type
        when :symbol_literal
          names << obj.jump(:ident, :op, :kw, :const).source
        when :string_literal
          names << obj.jump(:string_content).source
        end
      end
    end
    raise YARD::Parser::UndocumentableError, "alias/alias_method" if names.size != 2
    
    new_meth, old_meth = names[0].to_sym, names[1].to_sym
    old_obj = namespace.child(:name => old_meth, :scope => scope)
    new_obj = register MethodObject.new(namespace, new_meth, scope) do |o|
      o.visibility = visibility
      o.scope = scope
      o.add_file(parser.file, statement.line)
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