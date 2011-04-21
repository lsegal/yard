# (see Ruby::AliasHandler)
class YARD::Handlers::Ruby::Legacy::AliasHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /\Aalias(_method)?(\s|\()/

  process do
    if TkALIAS === statement.tokens.first
      tokens = statement.tokens[2..-1].to_s.split(/\s+/)
      names = [tokens[0], tokens[1]].map {|t| t.gsub(/^:(['"])?(.+?)\1?$|^(:)(.+)/, '\2') }
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
    end

    if old_obj
      new_obj.signature = old_obj.signature
      new_obj.source = old_obj.source
      new_obj.docstring = old_obj.docstring + YARD::Docstring.new(statement.comments)
      new_obj.docstring.object = new_obj
    else
      new_obj.signature = "def #{new_meth}" # this is all we know.
    end

    namespace.aliases[new_obj] = old_meth
  end
end