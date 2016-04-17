# Handles 'private', 'protected', and 'public' calls.
class YARD::Handlers::Ruby::VisibilityHandler < YARD::Handlers::Ruby::Base
  handles method_call(:private)
  handles method_call(:protected)
  handles method_call(:public)
  namespace_only

  process do
    return if (ident = statement.jump(:ident)) == statement
    case statement.type
    when :var_ref, :vcall
      self.visibility = ident.first.to_sym
    when :fcall, :command
      statement[1].traverse do |node|
        case node.type
        when :symbol; source = node.first.source
        when :string_content; source = node.source
        else next
        end

        begin
          prefix = scope == :instance ? YARD::CodeObjects::ISEP : YARD::CodeObjects::CSEP
          obj = P(namespace, prefix + source, :method)
          ensure_loaded!(obj)
          MethodObject.new(namespace, source, scope) {|o| o.visibility = ident.first }
        rescue YARD::Handlers::NamespaceMissingError
          log.debug "Visibility handler failed to change visibility of non-existent " +
                    "method '#{obj}' (#{statement.file}:#{statement.line})"
        end
      end
    end
  end
end