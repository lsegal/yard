# frozen_string_literal: true
# Handles RBS method aliases: `alias new_name old_name` and
# `alias self.new_name self.old_name`.
class YARD::Handlers::RBS::AliasHandler < YARD::Handlers::RBS::Base
  handles :alias
  namespace_only

  process do
    meth_scope = statement.visibility == :class ? :class : :instance
    old_meth = statement.old_name.to_sym
    old_obj = namespace.child(:name => old_meth, :scope => meth_scope)
    new_obj = register MethodObject.new(namespace, statement.name, meth_scope)
    namespace.aliases[new_obj] = old_meth

    if old_obj
      new_obj.signature = old_obj.signature
      new_obj.source = old_obj.source
      comments = [old_obj.docstring.to_raw, statement.comments].join("\n")
      doc = YARD::Docstring.parser.parse(comments, new_obj, self)
      new_obj.docstring = doc.to_docstring
      new_obj.docstring.line_range = statement.comments_range
      new_obj.docstring.object = new_obj
    end
  end
end
