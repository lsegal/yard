# Handles the Init_Libname() method
class YARD::Handlers::C::InitHandler < YARD::Handlers::C::Base
  MATCH = %r{\A\s*(?:static\s+)?void\s+[Ii]nit_(\w+)\s*}
  handles MATCH
  statement_class ToplevelStatement

  process do
    parse_block
    ns = namespace_for_variable(statement.declaration[MATCH, 1])
    if ns.is_a?(YARD::CodeObjects::NamespaceObject) && ns.docstring.blank?
      if statement.comments
        register_docstring(ns, statement.comments.source, statement)
      end
    end
  end
end
